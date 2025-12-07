with SERIAL;
with Log;
with System.Address_To_Access_Conversions;
with System.Storage_Elements; use System.Storage_Elements;
package body ELF.Loader is
   package Logger renames Log.Serial_Logger;
   function Prepare (File : in File_System.File_Descriptor) return ELF_Header is
      Header     : aliased ELF_Header;
      Read_Count : Integer;
   begin
      Read_Count := Read_Elf_Header (File, Header'Access);
      pragma Assert (Read_Count = ELF_Header'Size / 8);
      return Header;
   end Prepare;

   procedure Load_Segment
     (File           : in File_System.File_Descriptor;
      Program_Header : in ELF_Program_Header;
      CR3            : in out x86.vmm.CR3_register)
   is
      use all type System.Address;
      Kernel_CR3     : x86.vmm.CR3_register := x86.vmm.Get_Kernel_CR3;
      Read_Count : Integer;
      type Segment_Data is array (1 .. Program_Header.p_filesz) of Interfaces.Unsigned_8
         with Pack => True;

      package Conversion is new System.Address_To_Access_Conversions (Segment_Data);

      function Read_Segment_Data is new File_System.read (Segment_Data);

      function Map_Segment_Data is new x86.vmm.Map_Data (Segment_Data);

      Kernel_Buffer : System.Address;
      User_Allocated_Buffer : System.Address;
   begin
      Logger.Log_Info ("Reading segment" & Program_Header'Image);
      Kernel_Buffer := x86.vmm.kmalloc(CR3, Storage_Count (Program_Header.p_memsz), Is_Writable => True, Is_Usermode => True );

      if Kernel_Buffer = System.Null_Address  then
         Logger.Log_Error ("Unable to allocate segment for " & Program_Header'Image);
         raise Program_Error with "Unable to allocate elf segment";
      end if;


      File_System.Seek (File, Natural (Program_Header.p_offset), File_System.SEEK_SET);
      Read_Count := Read_Segment_Data (File, Conversion.To_Pointer (Kernel_Buffer));
      pragma Assert (Read_Count = Integer (Program_Header.p_filesz));

      User_Allocated_Buffer := x86.vmm.Process_To_Process_Map
        (Source_CR3     => Kernel_CR3,
         Source_Address => Kernel_Buffer,
         Dest_CR3       => CR3,
         Size           => Storage_Count (Program_Header.p_memsz),
         Hint           => Program_Header.p_vaddr);
      pragma Assert (User_Allocated_Buffer = Program_Header.p_vaddr);

      SERIAL.send_line
        ("Read " & Read_Count'Image & " bytes for segment at " & Program_Header.p_vaddr'Image);

      --  for i of Data loop
      --     SERIAL.send_string (Interfaces.Unsigned_8'Image (i) & " ");
      --  end loop;

      --  if not Map_Segment_Data
      --           (CR3, Program_Header.p_vaddr, Data, Is_Writable => True, Is_Usermode => True)
      --  then
      --     raise Program_Error with "Failed to map segment data";
      --  end if;

      SERIAL.send_line
        ("Mapped segment at "
         & Program_Header.p_vaddr'Image
         & " with size "
         & Program_Header.p_memsz'Image);
   end Load_Segment;

   procedure Kernel_Load
     (File   : in File_System.File_Descriptor;
      Header : in ELF_Header;
      CR3    : in out x86.vmm.CR3_register)
   is
      Program_Header : aliased ELF_Program_Header;
      Read_Count     : Integer;
      Seek_Result    : File_System.off_t;
   begin

      Seek_Result := File_System.Seek (File, Integer (Header.e_phoff), File_System.SEEK_SET);
      pragma Assert (Seek_Result /= -1);
      for i in 1 .. Header.e_phnum loop
         Read_Count := Read_Elf_Program_Header (File, Program_Header'Access);
         pragma Assert (Read_Count = ELF_Program_Header'Size / 8);

         if not Program_Header'Valid_Scalars then
            Logger.Log_Error ("Program_Header (" & i'Image & ") is not valid" & Program_Header'Image);
            pragma Assert (Program_Header'Valid_Scalars);
         end if;

         if Program_Header.p_type = PT_LOAD then
            SERIAL.send_line ("Loading segment " & i'Image & " at " & Program_Header.p_vaddr'Image);
            Load_Segment (File, Program_Header, CR3);
         end if;

         Seek_Result := File_System.Seek (File, Integer (Header.e_phoff), File_System.SEEK_SET);
         pragma Assert (Seek_Result /= -1);
         Seek_Result := File_System.Seek (File, Integer (i) * Read_Count, File_System.SEEK_CUR);
         pragma Assert (Seek_Result /= -1);
      end loop;
   end Kernel_Load;

end ELF.Loader;
