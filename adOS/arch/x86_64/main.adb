with config;
with SERIAL;
with VGA.GTF;
with x86;
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
with Interfaces.C.Strings;    use Interfaces.C.Strings;
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
   CR3 : CR3_register;

   function To_Hex is new Util.To_Hex (Integer_Address);
   function To_Hex is new Util.To_Hex (System.Address);
begin
   SERIAL.Init_COM (SERIAL.COM1, SERIAL.Baudrate'Last);
   Logger.Log_Info ("Starting adOS...");
   Logger.Log_Ok ("AdOS is loaded at");
   
   Logger.Log_Info ("   Virtual:  " & To_Hex (config.Kernel_Start) & " - " & To_Hex (config.Kernel_End));
   Logger.Log_Info ("   Physical: " & To_Hex (Limine.executable_address_response.physical_base) & " - " & To_Hex (Limine.executable_address_response.physical_base + config.Kernel_Size));
   Logger.Log_Info ("HHDM at: " & To_Hex (Integer_Address (Limine.hhdm_response.offset), 16));
   ----------------------------------
   ---- GDT and IDT initialization --
   ----------------------------------
   x86.gdt.initialize_gdt;
   SSE.Enable_SSE;
   x86.idt.init_idt;
   Logger.Log_Ok ("GDT and IDT initialized");

   ------------------------
   -- PIC initialization --
   ------------------------
   declare
      RSP : System.Address := 0;
   begin
      Asm ("movq %%rsp, %0", Outputs => (System.Address'Asm_Output ("=r", RSP)), Volatile => True);
      Logger.Log_Info ("RSP: " & To_Hex (Integer_Address (RSP), 16));
   end;
   pic.init;

   ------------------------
   -- PMM initialization --
   ------------------------
   Logger.Log_Info ("Number of memory map entries: " & Limine.memmap_response.Entry_Map_Count'Image);
   x86.pmm.Init (Limine.memmap_response);
   Logger.Log_Info ("Next free page: " & x86.pmm.Offset_To_Address (x86.pmm.Get_Next_Free_Page)'Image);
   x86.pmm.Print_PMM_Info;

   ------------------------
   -- VMM initialization --
   ------------------------

   Logger.Log_Info ("Initializing VMM");
   CR3 :=  Get_Current_CR3;
   Set_Kernel_CR3 (CR3);
   -- Identity_Map (CR3);
   x86.gdt.Set_Interrupt_Stack (Kernel_Alloc (CR3, 8192 * 2, Is_Writable => True), 8192 * 2);

   ---------------------
   -- Filesystem init --
   ---------------------
   Logger.Log_Info ("Atapi setup");
   Atapi.discoverAtapiDevices;
   File_System.ISO.init;

   Logger.Log_Info (Limine.framebuffer_response'Image);
   Logger.Log_Info (Limine.framebuffer_response.framebuffer_count'Image & " framebuffer(s) found");
   for i in Limine.framebuffer_response.framebuffers'Range loop
      Logger.Log_Info ("Framebuffer (" & i'Image & ")");
      Logger.Log_Info ("  Address: " & Limine.framebuffer_response.framebuffers (i).all.address'Image);
      Logger.Log_Info ("  Resolution: " & Limine.framebuffer_response.framebuffers (i).all.width'Image & "x" & Limine.framebuffer_response.framebuffers (i).all.height'Image);
      Logger.Log_Info ("  Pitch: " & Limine.framebuffer_response.framebuffers (i).all.pitch'Image);
   end loop;
   declare
      Width : Unsigned_64 := Limine.framebuffer_response.framebuffers (1).width;
      Height : Unsigned_64 := Limine.framebuffer_response.framebuffers (1).height;

      type vga_buffer is array (Unsigned_64 range 1 .. Width * Height) of Unsigned_32 with Pack => True;
      package Conversion is new System.Address_To_Access_Conversions (vga_buffer);

      Buffer : access vga_buffer := null;
   begin
      Buffer := Conversion.To_Pointer (Limine.framebuffer_response.framebuffers (1).all.address);
      Buffer (1 .. Width * Height) := (others => 255);
      Buffer (1 .. (Width * Height) / 2) := (others => 70);
      Buffer (1 .. (Width * Height) / 4) := (others => 90);
      Buffer (1 .. (Width * Height) / 8) := (others => 250);
   end;

   Programmable_Interval_Timer.set_timer_period (1);   
   -- Enable interrupts then PIT IRQ lines
   System.Machine_Code.Asm (Template => "sti", Volatile => True);
   PIC.Clear_Mask (0);
   PIC.Clear_Mask (1);
   Pic.Send_EOI (Pic.IRQ_Number (32));

   -----------------
   -- ELF Loading --
   -----------------
   Logger.Log_Info ("Preparing userland jump");
   declare
      use File_System;
      use Bounded_Path;
      FD             : File_Descriptor_With_Error := FD_ERROR;
      Program_Header : ELF.ELF_Header;
      File_To_Open : constant Path := Path (To_Path (Value (Limine.executable_cmdline_response.cmdline)));
      Userland_CR3 : CR3_Register := Create_CR3;
   begin
      Logger.Log_Info ("Loading file: " & To_String (File_To_Open));
      Identity_Map (Userland_CR3);
      FD := open (File_To_Open, 0);
      if FD = FD_ERROR then
         Logger.Log_Error ("Error opening ELF file: " & To_String (File_To_Open));
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

      Logger.Log_Info ("Entry point: " & Program_Header.e_entry'Image);
      Jump_To_Userspace (Program_Header.e_entry, Userland_CR3);
   end;

   <<Init_End>>
   System.Machine_Code.Asm (Template => "sti", Volatile => True);
   while True loop
      System.Machine_Code.Asm (Template => "hlt", Volatile => True);
   end loop;

   --  Loop forever.

end Main;
