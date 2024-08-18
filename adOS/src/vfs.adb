package body VFS is

    function Add_File
       (name : String; offset : off_t; size : Natural) return File_Descriptor
    is
    begin
        for i in Descriptors'Range loop
            if not Descriptors (i).Valid then
                Descriptors (i).Valid  := True;
                Descriptors (i).name   := name;
                Descriptors (i).offset := offset;
                Descriptors (i).size   := size;
                return i;
            end if;
        end loop;
        return FD_ERROR;
    end Add_File;

end VFS;
