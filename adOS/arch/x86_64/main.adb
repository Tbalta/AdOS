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
with VGA.Terminal;
with Limine;
with SSE;
procedure Main is
   package Logger renames Loggers.Serial_Logger;
   package VGA_Logger renames Loggers.VGA_Logger;
   CR3 : CR3_register;
begin
   --  VGA_Logger.Log_Info ("Starting adOS...");
   SERIAL.Init_COM (SERIAL.COM1, SERIAL.Baudrate'Last);
   Logger.Log_Info ("Starting adOS...");

   ------------------------------------
   --  Multiboot information display --
   ------------------------------------


   ----------------------------------
   ---- GDT and IDT initialization --
   ----------------------------------
   x86.gdt.initialize_gdt;
   SSE.Enable_SSE;
   x86.idt.init_idt;
   Logger.Log_Ok ("GDT and IDT initialized");

   Logger.Log_Ok ("SSE enabled");
   ------------------------
   -- PIC initialization --
   ------------------------
   Logger.Log_Info ("Limine.hhdm_request.response.address: " & Limine.hhdm_request.response.all'Image);
   --  Logger.Log_Info ("Limine.limine_memmap_response'Image: " & Limine.limine_memmap_response.all'Image);
   pic.init;

   ------------------------
   -- PMM initialization --
   ------------------------
   declare
      --  subtype multiboot_mmap_array is multiboot_mmap (1 .. Integer (entry_map_count));

      --  package Conversion is new System.Address_To_Access_Conversions (multiboot_mmap_array);
      --  entry_map : access multiboot_mmap_array := (Conversion.To_Pointer (info.mmap_addr));
      procedure print_mmap (s : System.Address);
      pragma Import (C, print_mmap, "print_mmap");
   begin
      Logger.Log_Info ("Number of memory map entries: " & Limine.limine_memmap_response.Entry_Map_Count'Image);
      --  print_mmap (Mem_Map_Address);
      x86.pmm.Init (Limine.mem_map_request.response.all);

      Logger.Log_Info
        ("Next free page: " & x86.pmm.Offset_To_Address (x86.pmm.Get_Next_Free_Page)'Image);
      x86.pmm.Print_PMM_Info;
   end;

   ------------------------
   -- VMM initialization --
   ------------------------

   Logger.Log_Info ("Initializing VMM");

   CR3 :=  Get_Current_CR3;
   Print_Mapped_Memory (CR3);
   Logger.Log_Info ("CR3 address: " & CR3'Image);
   Set_Kernel_CR3 (CR3);
   --  Print_Mapped_Memory (CR3);
   Identity_Map (CR3);

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

   -- VGA.load_palette ("vga_tui.hex");

   Logger.Log_Info (Limine.framebuffer_response.all'Image);
   Logger.Log_Info (Limine.framebuffer_response.framebuffer_count'Image & " framebuffer(s) found");
   for i in Limine.framebuffer_response.framebuffers'Range loop
      Logger.Log_Info ("Framebuffer " & Limine.framebuffer_response.framebuffers (i).all'Image & ":");
      Logger.Log_Info ("  Address: " & Limine.framebuffer_response.framebuffers (i).all.address'Image);
      Logger.Log_Info ("  Resolution: " & Limine.framebuffer_response.framebuffers (i).all.width'Image & "x" & Limine.framebuffer_response.framebuffers (i).all.height'Image);
      Logger.Log_Info ("  Pitch: " & Limine.framebuffer_response.framebuffers (i).all.pitch'Image);
   end loop;
   declare
      --  use File_System;
      --  fd : File_System.File_Descriptor_With_Error := FD_ERROR;

      Width : Unsigned_64 := Limine.framebuffer_response.framebuffers (1).width;
      Height : Unsigned_64 := Limine.framebuffer_response.framebuffers (1).height;

      type vga_buffer is array (Unsigned_64 range 1 .. Width * Height) of Unsigned_32 with Pack => True;
      package Conversion is new System.Address_To_Access_Conversions (vga_buffer);

      Buffer : access vga_buffer := null;
      --  count  : Integer := 0;

      --  procedure libvga_switch_mode13h;
      --  pragma Import (C, libvga_switch_mode13h, "libvga_switch_mode13h");
   begin
      --  libvga_switch_mode13h;
      --  --  VGA.Set_Graphic_Mode (320, 200, 256);
      --  --  VGA.load_palette ("vga_gui.hex");
      Logger.Log_Info ("Switching to graphical mode...");
      Logger.Log_Info (Width'Image & "x" & Height'Image);
      Buffer := Conversion.To_Pointer (Limine.framebuffer_response.framebuffers (1).all.address);
      Buffer (1 .. Width * Height) := (others => 255);
      Buffer (1 .. (Width * Height) / 2) := (others => 70);
      Buffer (1 .. (Width * Height) / 4) := (others => 90);
      Buffer (1 .. (Width * Height) / 8) := (others => 250);
   end;
   --  VGA.Set_Text_Mode (80, 25, 16);
   --  VGA.load_palette ("vga_tui.hex");
   --  Logger.Log_Info ("Hello World!");
   --  Logger.Log_Info ("Hello World!");

   Programmable_Interval_Timer.set_timer_period (1);
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
      File_To_Open : constant Path := Path' ("bin/test.elf");
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
