with SERIAL;
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
with Log;
with Ada.Assertions;
with Util;
with VGA;
with Interfaces;
with VGA.CRTC;
procedure Main (magic : Interfaces.Unsigned_32; multiboot_address : System.Address) is
   package MultiBoot_Conversion is new System.Address_To_Access_Conversions (multiboot_info);
   info : access multiboot_info := MultiBoot_Conversion.To_Pointer (multiboot_address);

   package Logger renames Log.Serial_Logger;
   CR3 : CR3_register;
begin
   SERIAL.serial_init (SERIAL.Baudrate'Last);
   Logger.Log_Info ("Starting adOS...");

   ------------------------------------
   --  Multiboot information display --
   ------------------------------------
   SERIAL.send_line ("magic: " & magic'Image);
   SERIAL.send_line ("multiboot_info: " & info.all'Image);
   declare
      str : String := Util.Read_String_From_Address (info.cmdline);
   begin
      SERIAL.send_line ("cmdline: " & str);
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
      print_mmap (multiboot_address);
      x86.pmm.Init (entry_map.all);
      SERIAL.send_line
        ("Next free page: " & x86.pmm.Offset_To_Address (x86.pmm.Get_Next_Free_Page)'Image);
   end;

   ------------------------
   -- VMM initialization --
   ------------------------

   Logger.Log_Info ("Initializing VMM");
   CR3 := Create_CR3;
   Logger.Log_Info ("CR3 address: " & To_Address (CR3.Address)'Image);
   Identity_Map (CR3);
   Load_CR3 (CR3);
   Set_Kernel_CR3 (CR3);
   Logger.Log_Ok ("CR3 Loaded");
   Enable_Paging;
   Logger.Log_Ok ("Paging enabled");

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
      buffer : Read_Type;
      read   : Integer;
      function Read_Char is new File_System.read (Read_Type => Read_Type);
   begin
      Logger.Log_Info ("ISO filesystem initialized");
      FD := open ("test2.txt", 0);
      if FD = FD_ERROR then
         Logger.Log_Error ("Error opening file");
         goto Init_End;
      end if;

      read := Read_Char (FD, buffer);
      SERIAL.send_line ("read:" & buffer (1 .. read));
      if close (FD) = 0 then
         Logger.Log_Ok ("File closed successfully");
      else
         Logger.Log_Error ("Error closing file");
      end if;
   end;

   --  VGA.enable_320x200x256;
   VGA.Set_Graphic_Mode (320, 200, 256);
   VGA.CRTC.Dump_CRTC_Register;
   declare
      FB : System.Address;
      procedure memset (buf: System.Address; c : Interfaces.Unsigned_8; n : interfaces.Unsigned_32);
      pragma Import (C, memset, "memset");
   begin
      FB :=  VGA.Get_Frame_Buffer;
      Logger.Log_Info ("Frame_Buffer: " & FB'Image);
      memset (FB, 5, 320*200);
      memset (FB, 70, 320*150);
      memset (FB, 90, 320*100);
      memset (FB, 250, 320*50);
      memset (FB, 210, 160);
      
   end;

   -----------------
   -- ELF Loading --
   -----------------
   declare
      use File_System;
      FD             : File_Descriptor_With_Error := FD_ERROR;
      Program_Header : ELF.ELF_Header;
   begin
      FD := open ("bin/test.elf", 0);
      if FD = FD_ERROR then
         Logger.Log_Error ("Error opening file");
         goto Init_End;
      end if;

      Program_Header := ELF.Loader.Prepare (FD);
      ELF.Loader.Kernel_Load (FD, Program_Header, CR3);
      Logger.Log_Ok ("ELF file loaded in memory");
      if close (FD) /= 0 then
         Logger.Log_Error ("Error closing ELF file");
      else
         Logger.Log_Ok ("ELF file closed successfully");
      end if;

      SERIAL.send_line ("Entry point: " & To_Integer (Program_Header.e_entry)'Image);
      Jump_To_Userspace (Program_Header.e_entry, CR3);
   end;

   <<Init_End>>
   System.Machine_Code.Asm (Template => "sti", Volatile => True);
   while True loop
      System.Machine_Code.Asm (Template => "hlt", Volatile => True);
   end loop;

   --  Loop forever.

end Main;
