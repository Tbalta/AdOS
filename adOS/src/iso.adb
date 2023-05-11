with SERIAL;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
package body ISO is
    function open (path : String; flag : Integer) return File_Descriptor is
    begin
        return 0;
    end open;

    function read
       (fd : File_Descriptor; buffer : System.Address; count : Positive)
        return Integer
    is
    begin
        return 0;
    end read;

    function seek
       (fd : File_Descriptor; offset : off_t; wh : whence) return off_t
    is
    begin
        return 0;
    end seek;

    function close (fd : File_Descriptor) return Integer is
    begin
        return 0;
    end close;

    procedure init is
        init_buffer : System.Address := Read_Block (16#10#);
        use ISO_PRIM_DESC_CONVERTER;
        primary_descriptor : access iso_prim_voldesc :=
           To_Pointer (init_buffer);
        Identifier         : String (1 .. 5);
        Count              : Natural                 := 0;
    begin
        --  SERIAL.send_line
        --     ("Identifier address: " & Integer (init_buffer'Address)'Image);
        SERIAL.send_line
           ("[iso.adb:38]Identifier (should be CD001)" &
            To_Ada (primary_descriptor.vol_id, False));
        --  SERIAL.send_line ("size: " & Integer (iso_dir'Size)'Image);
        root_lba     := primary_descriptor.root_dir.data_blk.le;
        root_dirsize := primary_descriptor.root_dir.file_size.le;
        --  SERIAL.send_line (primary_descriptor.root_dir.file_size.le'Image);

        --  SERIAL.send_line (primary_descriptor.root_dir.dir_size'Image);
        --  SERIAL.send_line (primary_descriptor.root_dir.ext_size'Image);
        list_file (root_lba, Integer (root_dirsize));
    end init;

    procedure list_file (dir_lba : Unsigned_32; dir_size_param : in Integer) is
        file_buffer : System.Address := Read_Block (Integer (dir_lba));
        use ISO_FILE_DESC_CONVERTER;
        subtype iso_dir_ptr is ISO_FILE_DESC_CONVERTER.Object_Pointer;
        current_file : iso_dir_ptr := iso_dir_ptr (To_Pointer (file_buffer));
        lba          : Unsigned_32 := dir_lba;
        dir_size     : Integer     := dir_size_param;
    begin
        for I in 1 .. 2 loop
            current_file :=
               To_Pointer
                  (To_Address (current_file) +
                   Storage_Offset (current_file.dir_size));
        end loop;
        SERIAL.send_line ("Directory size: " & Integer'Image (dir_size));
        while dir_size > 0 loop
            while current_file.dir_size /= 0 loop
                declare
                    subtype current_file_name is
                       char_array (0 .. size_t (current_file.idf_len) - 1);
                    file_name : current_file_name;
                    for file_name'Address use current_file.idf'Address;
                begin
                    SERIAL.send_line ("File: " & To_Ada (file_name, False));
                    current_file :=
                       To_Pointer
                          (To_Address (current_file) +
                           Storage_Offset (current_file.dir_size));
                    --  dir_size     := dir_size - Integer (current_file.dir_size);
                end;
            end loop;
            dir_size    := dir_size - BLOCK_SIZE;
            lba         := lba + 1;
            file_buffer := Read_Block (Integer (lba));
            current_file := iso_dir_ptr (To_Pointer (file_buffer));

        end loop;

    end list_file;

end ISO;
