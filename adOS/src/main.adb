with SERIAL;
with VGA.GTF;
with x86.gdt;
with x86.idt;
with x86.pmm;                 use x86.pmm;
with x86.vmm;                 use x86.vmm;
with pic;
with System.Machine_Code;
with Atapi;
with Ada.Unchecked_Conversion;
with Interfaces;              use Interfaces;
with Interfaces.C;            use Interfaces.C;
with System.Address_To_Access_Conversions;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with MultiBoot;               use MultiBoot;
with System.Machine_Code;     use System.Machine_Code;
with File_System;
with File_System.ISO;
with ELF;
with ELF.Loader;
with x86.Userspace;           use x86.Userspace;
with Loggers;
with Ada.Assertions;
with Util;
with VGA;
with VGA.GTF;
with Interfaces;
with VGA.CRTC;
with Programmable_Interval_Timer;
with Keyboard;

procedure Main (magic : Interfaces.Unsigned_32; multiboot_address : System.Address) is
   package MultiBoot_Conversion is new System.Address_To_Access_Conversions (multiboot_info);
   info : access multiboot_info := MultiBoot_Conversion.To_Pointer (multiboot_address);

   package Logger renames Loggers;
   package VGA_Logger renames Loggers.VGA_Logger;
   CR3 : CR3_register;
begin
   VGA_Logger.Log_Info ("Starting adOS...");
   SERIAL.Init_COM (SERIAL.COM1, SERIAL.Baudrate'Last);
   Logger.Log_Info ("Starting adOS...");

   ------------------------------------
   --  Multiboot information display --
   ------------------------------------
   Logger.Log_Info ("magic: " & magic'Image);
   Logger.Log_Info ("multiboot_info: " & info.all'Image);
   declare
      str : String := Util.Read_String_From_Address (info.cmdline);
   begin
      Logger.Log_Info ("cmdline: " & str);
   end;

   ----------------------------------
   ---- GDT and IDT initialization --
   ----------------------------------
   x86.gdt.initialize_gdt;
   x86.idt.init_idt;

   ------------------------
   -- PIC initialization --
   ------------------------
   pic.init;

   ------------------------
   -- PMM initialization --
   ------------------------
   declare
      entry_map_size  : constant Storage_Count := Storage_Count (info.mmap_length);
      entry_map_count : constant Integer :=
        Integer (entry_map_size / (multiboot_mmap_entry'Size / Storage_Unit));
      subtype multiboot_mmap_array is multiboot_mmap (1 .. Integer (entry_map_count));

      package Conversion is new System.Address_To_Access_Conversions (multiboot_mmap_array);
      entry_map : access multiboot_mmap_array := (Conversion.To_Pointer (info.mmap_addr));

      procedure print_mmap (s : System.Address);
      pragma Import (C, print_mmap, "print_mmap");
   begin
      Logger.Log_Info ("mmap_count / size: " & entry_map_count'Image & " / " & entry_map_size'Image);
      print_mmap (multiboot_address);
      x86.pmm.Init (entry_map.all);
      Logger.Log_Info
        ("Next free page: " & x86.pmm.Offset_To_Address (x86.pmm.Get_Next_Free_Page)'Image);
   end;

   ------------------------
   -- VMM initialization --
   ------------------------

   Logger.Log_Info ("Initializing VMM");
   CR3 := Create_CR3;
   Logger.Log_Info ("CR3 address: " & CR3'Image);
   Identity_Map (CR3);
   Load_CR3 (CR3);
   Set_Kernel_CR3 (CR3);
   Logger.Log_Ok ("CR3 Loaded");
   Enable_Paging;
   Logger.Log_Ok ("Paging enabled");
   VGA_Logger.Log_Ok ("Paging enabled");

   ---------------------
   -- Filesystem init --
   ---------------------
   Logger.Log_Info ("Atapi setup");
   Atapi.discoverAtapiDevices;
   File_System.ISO.init;
   declare
      use File_System;
      FD : File_Descriptor_With_Error := FD_ERROR;

      subtype Read_Type is String (1 .. 512);
      buffer : aliased Read_Type;
      read   : Integer;
      function Read_Char is new File_System.read (Read_Type => Read_Type);
   begin
      Logger.Log_Info ("ISO filesystem initialized");
      FD := open ("test2.txt", 0);
      if FD = FD_ERROR then
         Logger.Log_Error ("Error opening file test2.txt");
         goto Init_End;
      end if;

      read := Read_Char (FD, buffer'Access);
      Logger.Log_Info ("read:" & buffer (1 .. read));
      if close (FD) = 0 then
         Logger.Log_Ok ("File closed successfully");
      else
         Logger.Log_Error ("Error closing file");
      end if;
   end;

   VGA.load_palette ("vga_tui.hex");

   declare
      use File_System;
      fd : File_System.File_Descriptor_With_Error := FD_ERROR;

      type vga_buffer is array (Integer range 1 .. 320 * 200) of Unsigned_8 with Pack => True;
      package Conversion is new System.Address_To_Access_Conversions (vga_buffer);

      Buffer : access vga_buffer := null;
      count  : Integer := 0;
   begin
      VGA.Set_Graphic_Mode (320, 200, 256);
      VGA.load_palette ("vga_gui.hex");
      Buffer := Conversion.To_Pointer (VGA.Get_Frame_Buffer);
      Buffer (1 .. 320 * 200) := (others => 5);
      Buffer (1 .. 320 * 150) := (others => 70);
      Buffer (1 .. 320 * 100) := (others => 90);
      Buffer (1 .. 320 * 50) := (others => 250);
   end;

   Programmable_Interval_Timer.set_timer_period (10);
   --  Keyboard.Init;
   -- ?? sti here
   System.Machine_Code.Asm (Template => "sti", Volatile => True);
   PIC.Clear_Mask (0);
   PIC.Clear_Mask (1);

   -----------------
   -- ELF Loading --
   -----------------
   declare
      use File_System;
      FD             : File_Descriptor_With_Error := FD_ERROR;
      Program_Header : ELF.ELF_Header;
      File_To_Open : constant Path := Path (Util.Read_String_From_Address (info.cmdline));
      Userland_CR3 : CR3_Register := Create_CR3;
   begin
      Logger.Log_Info ("Loading file: " & String (File_To_Open));
      Identity_Map (Userland_CR3);
      FD := open (File_To_Open, 0);
      if FD = FD_ERROR then
         Logger.Log_Error ("Error opening ELF file: " & String (File_To_Open));
         goto Init_End;
      end if;

      Program_Header := ELF.Loader.Get_Elf_Header (FD);
      ELF.Loader.Load_Elf (FD, Program_Header, Userland_CR3);
      Logger.Log_Ok ("ELF file loaded in memory");
      if close (FD) /= 0 then
         Logger.Log_Error ("Error closing ELF file");
      else
         Logger.Log_Ok ("ELF file closed successfully");
      end if;

      Logger.Log_Info ("Entry point: " & To_Integer (Program_Header.e_entry)'Image);
      Jump_To_Userspace (Program_Header.e_entry, Userland_CR3);
   end;

   <<Init_End>>
   System.Machine_Code.Asm (Template => "sti", Volatile => True);
   while True loop
      System.Machine_Code.Asm (Template => "hlt", Volatile => True);
   end loop;

   --  Loop forever.

end Main;
