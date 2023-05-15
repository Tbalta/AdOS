------------------------------------------------------------------------------
--                                   AdOS                                   --
--                                                                          --
--  File    : iso.ads                                                       --
------------------------------------------------------------------------------

--  This package provide basic ISO9660 filesystem support.
--  Only read-only access is supported.
with Interfaces;   use Interfaces;
with Interfaces.C; use Interfaces.C;
with System;
with System.Address_To_Access_Conversions;

generic
  BLOCK_SIZE : Positive;
  with function Read_Block (Lba : Integer) return System.Address;
package ISO is
  pragma Preelaborate;
  MAX_FILES : constant Positive := 256;

  type off_t is new Integer;
  type File_Descriptor is new Integer range -1 .. MAX_FILES - 1;

  type whence is (SEEK_SET, SEEK_CUR, SEEK_END);

  root_lba     : Natural;
  root_dirsize : Natural;

  function open (path : String; flag : Integer) return File_Descriptor;
  function read
   (fd : File_Descriptor; buffer_param : System.Address; count_param : Natural)
    return Integer;
  function seek
   (fd : File_Descriptor; offset : off_t; wh : whence) return off_t;
  function close (fd : File_Descriptor) return Integer;
  procedure init;
  procedure list_file (dir_lba, dir_size_param : in Natural);

  type endian32 is record
    le : Unsigned_32;
    be : Unsigned_32;
  end record with
   Pack => True, Convention => C, Size => 64;

  type endian16 is record
    le : Unsigned_16;
    be : Unsigned_16;
  end record with
   Size => 32, Pack => True, Convention => C;

  type Iso_Flag_Value is
   (Hidden, Directory, Associated, Extended, Permission_In_Extent, Reserved1,
    Reserved2, Final_Extent);
  type Iso_Flag_Array is array (Iso_Flag_Value) of Boolean with
   Pack => True;

  type File_Information is record
    size   : Natural;
    lba    : Natural;
    offset : Natural := 0;
  end record;

  type File_Information_Array is array (File_Descriptor) of File_Information;
  type File_Information_Counter is mod MAX_FILES;

  File_Descriptors : File_Information_Array;
  File_Count       : File_Information_Counter := 0;
  type iso_dir is record
    dir_size  : Unsigned_8;  -- iso9660.h:71
    ext_size  : Unsigned_8;  -- iso9660.h:72
    data_blk  : endian32;  -- iso9660.h:73
    file_size : endian32;  -- iso9660.h:74
    date      : Interfaces.C.char_array (0 .. 6);  -- iso9660.h:75
    flags     : Iso_Flag_Array;  -- iso9660.h:76
    unit_size : Unsigned_8;  -- iso9660.h:79
    gap_size  : Unsigned_8;  -- iso9660.h:80
    vol_seq   : endian16;  -- iso9660.h:82
    idf_len   : Unsigned_8;  -- iso9660.h:83
    idf       : Interfaces.C.char_array (0 .. 0);  -- iso9660.h:84
  end record with
   Convention => C,  -- iso9660.h:70
   Pack       => True, Size => 34 * 8;

  type iso_prim_voldesc is record
    vol_desc_type   : Unsigned_8;
    vol_id          : char_array (0 .. 4);
    vol_version     : Unsigned_8;
    unused1         : Unsigned_8;
    system_id       : char_array (0 .. 31);
    vol_id2         : char_array (0 .. 31);
    unused2         : char_array (0 .. 7);
    vol_blk_count   : endian32;
    unused3         : char_array (0 .. 31);
    vol_set_size    : endian16;
    vol_seq_num     : endian16;
    vol_blk_size    : endian16;
    path_table_size : endian32;

    le_path_table_blk  : Unsigned_32;  -- iso9660.h:117
    le_opath_table_blk : Unsigned_32;  -- iso9660.h:118
    be_path_table_blk  : Unsigned_32;  -- iso9660.h:120
    be_opath_table_blk : Unsigned_32;  -- iso9660.h:121
    root_dir           : iso_dir;
    unused4            : char_array (0 .. (34 - (iso_dir'Size / 8)));
  end record with
   Pack => True;

  package ISO_PRIM_DESC_CONVERTER is new System.Address_To_Access_Conversions
   (iso_prim_voldesc);
  subtype iso_prim_voldesc_ptr is ISO_PRIM_DESC_CONVERTER.Object_Pointer;

  package ISO_FILE_DESC_CONVERTER is new System.Address_To_Access_Conversions
   (iso_dir);
  subtype iso_dir_ptr is ISO_FILE_DESC_CONVERTER.Object_Pointer;

private

end ISO;
