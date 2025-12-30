------------------------------------------------------------------------------
--                                ELF.LOADER                                --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Loggers;
with System.Address_To_Access_Conversions;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;

package body ELF.Loader is
   package Logger renames Loggers.Serial_Logger;

   ----------------
   -- Get_Elf_Header --
   ----------------
   function Get_Elf_Header (File : in File_System.File_Descriptor) return ELF_Header is
      Header     : aliased ELF_Header;
      Read_Count : Integer;
   begin
      Read_Count := Read_Elf_Header (File, Header'Access);
      pragma Assert (Read_Count = ELF_Header'Size / 8);
      pragma Assert (Header'Valid_Scalars);
      return Header;
   end Get_Elf_Header;


   ------------------
   -- Load_Segment --
   ------------------
   procedure Load_Segment
     (File           : in File_System.File_Descriptor;
      Program_Header : in ELF_Program_Header;
      CR3            : in out x86.vmm.CR3_register)
   is
      use all type System.Address;
      Kernel_CR3 : x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
      Read_Count : Integer;
      type Segment_Data is array (1 .. Program_Header.p_filesz) of Interfaces.Unsigned_8
      with Pack => True;

      package Conversion is new System.Address_To_Access_Conversions (Segment_Data);

      function Read_Segment_Data is new File_System.read (Segment_Data);

      procedure memset (Address : System.Address; Value : Unsigned_8; Size : Unsigned_32);
      pragma Import (C, memset, "memset");

      Kernel_Buffer         : System.Address;
      User_Allocated_Buffer : System.Address;
      Segment_Page_Offset : Storage_Offset := Storage_Offset (To_Integer (Program_Header.p_vaddr) mod 4096);
   begin
      Logger.Log_Info ("Reading segment" & Program_Header'Image);
      Kernel_Buffer := x86.vmm.Kernel_Alloc (Kernel_CR3, Program_Header.p_memsz, Is_Writable => True, Is_Usermode => True);
      memset (Kernel_Buffer, 0, Unsigned_32 (Program_Header.p_memsz));

      if Kernel_Buffer = System.Null_Address then
         Logger.Log_Error ("Unable to allocate segment for " & Program_Header'Image);
         raise Program_Error with "Unable to allocate elf segment";
      end if;

      File_System.Seek (File, Program_Header.p_offset, File_System.SEEK_SET);
      Read_Count := Read_Segment_Data (File, Conversion.To_Pointer (Kernel_Buffer + Segment_Page_Offset));
      pragma Assert (Read_Count = Integer (Program_Header.p_filesz));

      User_Allocated_Buffer :=
        x86.vmm.Process_To_Process_Map
          (Source_CR3     => Kernel_CR3,
           Source_Address => Kernel_Buffer,
           Dest_CR3       => CR3,
           Size           => Program_Header.p_memsz,
           Hint           => Program_Header.p_vaddr);

      pragma Assert (User_Allocated_Buffer = Program_Header.p_vaddr);

      x86.vmm.Memory_Unmap
        (CR3       => Kernel_CR3,
         Address   => Kernel_Buffer,
         Size      => Storage_Count (Program_Header.p_memsz),
         Free_Page => False);

      Logger.Log_Info
        ("Mapped segment at "
         & Program_Header.p_vaddr'Image
         & " with size "
         & Program_Header.p_memsz'Image);
   end Load_Segment;


   --------------
   -- Load_Elf --
   --------------
   procedure Load_Elf
     (File   : in File_System.File_Descriptor;
      Header : in ELF_Header;
      CR3    : in out x86.vmm.CR3_register)
   is
      Program_Header : aliased ELF_Program_Header;
      Read_Count     : Integer;
      Seek_Result    : File_System.off_t;
   begin

      Seek_Result := File_System.Seek (File, Header.e_phoff, File_System.SEEK_SET);
      pragma Assert (Seek_Result /= -1);

      for i in 1 .. Header.e_phnum loop
         Read_Count := Read_Elf_Program_Header (File, Program_Header'Access);
         pragma Assert (Read_Count = ELF_Program_Header'Size / 8);

         if not Program_Header'Valid_Scalars then
            Logger.Log_Error
              ("Program_Header (" & i'Image & ") is not valid" & Program_Header'Image);
            pragma Assert (Program_Header'Valid_Scalars);
         end if;

         if Program_Header.p_type = PT_LOAD then
            Logger.Log_Info ("Loading segment " & i'Image & " at " & Program_Header.p_vaddr'Image);
            Load_Segment (File, Program_Header, CR3);
         end if;

         Seek_Result := File_System.Seek (File, Header.e_phoff, File_System.SEEK_SET);
         pragma Assert (Seek_Result /= -1);
         Seek_Result :=
           File_System.Seek
             (File,
              Storage_Offset (i * (ELF_Program_Header'Size / Storage_Unit)),
              File_System.SEEK_CUR);
         pragma Assert (Seek_Result /= -1);
      end loop;
   end Load_Elf;

end ELF.Loader;
