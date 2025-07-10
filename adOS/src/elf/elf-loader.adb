with SERIAL;
package body ELF.Loader is

    function Prepare (File : in VFS.File_Descriptor) return ELF_Header is
        Header     : ELF_Header;
        Read_Count : Integer;
    begin
        Read_Count := Read_Elf_Header (File, Header);
        pragma Assert (Read_Count = ELF_Header'Size / 8);
        return Header;
    end Prepare;

    procedure Load_Segment
       (File : in VFS.File_Descriptor; Program_Header : in ELF_Program_Header;
        CR3  : in out x86.vmm.CR3_register)
    is
        Read_Count : Integer;
        type Segment_Data is
           array (1 .. Program_Header.p_filesz) of Interfaces.Unsigned_8;
        function Read_Segment_Data is new File_System.read (Segment_Data);
        Data : Segment_Data;

        function Map_Segment_Data is new x86.vmm.Map_Data (Segment_Data);
    begin
        File_System.Seek
           (File, Natural (Program_Header.p_offset), VFS.SEEK_SET);
        Read_Count := Read_Segment_Data (File, Data);
        SERIAL.send_line
          ("Read " & Read_Count'Image & " bytes for segment at " &
           Program_Header.p_vaddr'Image);

      for i of Data loop
         SERIAL.send_string (Interfaces.Unsigned_8'Image (i) & " ");
      end loop;
        pragma Assert (Read_Count = Integer (Program_Header.p_filesz));

        if not Map_Segment_Data (CR3, Program_Header.p_vaddr, Data, Is_Writable => True, Is_Usermode => True) then
            raise Program_Error with "Failed to map segment data";
        end if;

        SERIAL.send_line
          ("Mapped segment at " & Program_Header.p_vaddr'Image &
           " with size " & Program_Header.p_filesz'Image);
    end Load_Segment;

    procedure Kernel_Load
       (File : in     VFS.File_Descriptor; Header : in ELF_Header;
        CR3  : in out x86.vmm.CR3_register)
    is
        Program_Header : ELF_Program_Header;
        Read_Count     : Integer;
        Seek_Result : VFS.off_t;
    begin
        Seek_Result := File_System.Seek (File, Integer (Header.e_phoff), VFS.SEEK_SET);
        pragma Assert (Seek_Result /= -1);
   
        for i in 1 .. Header.e_phnum loop
            Read_Count := Read_Elf_Program_Header (File, Program_Header);
            pragma Assert (Read_Count = ELF_Program_Header'Size / 8);

            if Program_Header.p_type = PT_LOAD then
               SERIAL.send_line
                 ("Loading segment " & i'Image &
                  " at " & Program_Header.p_vaddr'Image);
                Load_Segment (File, Program_Header, CR3);
            end if;
        end loop;
    end Kernel_Load;

end ELF.Loader;
