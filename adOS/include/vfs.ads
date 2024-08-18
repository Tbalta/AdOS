with Interfaces;
package VFS is
    pragma Preelaborate;
    type File_Descriptor_With_Error is new Integer range -1 .. 255;
    subtype File_Descriptor is File_Descriptor_With_Error range 0 .. 255;

    FD_ERROR : constant File_Descriptor_With_Error := -1;

    type whence is (SEEK_SET, SEEK_CUR, SEEK_END);
    subtype off_t is Integer;

private
    function Add_File
       (name : String; offset : off_t; size : Natural) return File_Descriptor;
    --  Device specific descriptors
    type File is record
        Valid  : Boolean           := False;
        name   : String (1 .. 255) := (others => ' ');
        offset : off_t             := 0;
        size   : Natural           := 0;
    end record;

    type File_Array is array (File_Descriptor) of File;
    Descriptors : File_Array := (others => <>);

end VFS;
