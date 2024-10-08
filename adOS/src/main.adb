with SERIAL;
with x86.gdt;
with x86.idt;
with x86.pmm;                 use x86.pmm;
with x86.vmm;
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
with VFS;                     use VFS;
with VFS.ISO;
--  with Interfaces; use Interfaces;
procedure Main
  (magic : Interfaces.Unsigned_32; info : access MultiBoot.multiboot_info)
is

   --  Suppress some checks to prevent undefined references during linking to
   --
   --    __gnat_rcheck_CE_Range_Check
   --    __gnat_rcheck_CE_Overflow_Check
   --
   --  These are Ada Runtime functions (see also GNAT's a-except.adb).

   pragma Suppress (Index_Check);
   pragma Suppress (Overflow_Check);
   pragma Suppress (All_Checks);
   procedure discover_atapi_drive;
   pragma Import (C, discover_atapi_drive, "discover_atapi_drive");
   procedure print_mmap (s : System.Address);
   pragma Import (C, print_mmap, "print_mmap");
begin

   --  Clear (BLACK);
   --  Put_String (0, 0, BRIGHT, BLACK, "Ada says: Hello world!");
   SERIAL.serial_init (SERIAL.Baudrate'Last);
   x86.gdt.initialize_gdt;
   x86.idt.init_idt;
   SERIAL.send_line ("test");
   SERIAL.send_line ("magic: " & magic'Image);
   SERIAL.send_line ("flags: " & info.all.flags'Image);
   declare
      function strlen (s : System.Address) return Interfaces.C.size_t;
      pragma Import (C, strlen, "strlen");
      length : Integer :=
        Integer (strlen (To_Address (Integer_Address (info.all.cmdline))));
      subtype cmdLine is
        Interfaces.C.char_array (1 .. Interfaces.C.size_t (length));
      str : String (1 .. length);

      package Conversion is new System.Address_To_Access_Conversions (cmdLine);
      cmdLine_access : access cmdLine :=
        Conversion.To_Pointer
          (To_Address (Integer_Address (info.all.cmdline)));
   begin
      for i in 1 .. length loop
         str (i) := Character (cmdLine_access.all (size_t (i)));
      end loop;
      SERIAL.send_line ("cmdline: " & str);
   end;

   pic.init;
   ------------------------
   -- PMM initialization --
   ------------------------
   declare
      entry_map_size  : constant Unsigned_64 :=
        Unsigned_64 (info.all.mmap_length);
      entry_map_count : constant Unsigned_64 :=
        entry_map_size / (multiboot_mmap_entry'Size / 8);
      subtype multiboot_mmap_array is
        multiboot_mmap (1 .. Integer (entry_map_count));
      package Conversion is new System.Address_To_Access_Conversions
        (multiboot_mmap_array);
      entry_map : access multiboot_mmap_array :=
        (Conversion.To_Pointer
           (To_Address (Integer_Address (info.all.mmap_addr))));
   begin
      print_mmap (info.all'Address);
      x86.pmm.Init (entry_map.all);
      SERIAL.send_line
        ("Next free page: " &
         x86.pmm.Offset_To_Address (x86.pmm.Get_Next_Free_Page)'Image);
   end;

   ------------------------
   -- VMM initialization --
   ------------------------
   --  Asm ("int $0x0");
   SERIAL.send_line ("VMM initialization");
   declare
      use x86.vmm;
      CR3 : CR3_register := Create_CR3;
   begin
      Identity_Map (CR3);
      Load_CR3 (CR3);
      Enable_Paging;
   end;
   SERIAL.send_line ("Paging enabled");

   SERIAL.send_line ("Atapi setup");

   Atapi.discoverAtapiDevices;
   declare
      package VFS_ISO is new VFS.ISO
        (Block_Range  => Atapi.SECTOR_BUFFER_INDEX,
         Block_Type   => Atapi.SECTOR_BUFFER,
         Read_Block   => Atapi.read_block);
      FD     : VFS.File_Descriptor_With_Error;
      subtype my_arr is Interfaces.C.char_array (1 .. 512);
      buffer : my_arr := (others => Interfaces.C.char'Val(0));
      read   : Integer;
      function Read_Char is new VFS_ISO.read (Read_Type => my_arr);
   begin
      VFS_ISO.init;
      FD := VFS_ISO.open ("test2.txt", 0);
      if FD = FD_ERROR then
         SERIAL.send_line ("Error opening file");
         goto Init_End;
      end if;

      read := Read_Char (FD, buffer);

      SERIAL.send_line
        (To_Ada (buffer (1 .. Interfaces.C.size_t (read)), False));
   end;

   <<Init_End>>
   System.Machine_Code.Asm (Template => "sti", Volatile => True);
   while True loop
      System.Machine_Code.Asm (Template => "hlt", Volatile => True);
   end loop;

   --  Loop forever.

end Main;
