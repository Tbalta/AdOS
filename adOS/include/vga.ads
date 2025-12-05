------------------------------------------------------------------------------
--                                   VGA                                    --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    VGA mode configuration                                                --
------------------------------------------------------------------------------

with x86.Port_IO;
with System;
with Interfaces; use Interfaces;
with File_System;
package VGA is
   pragma Preelaborate;

   
   type Register_Index is new Unsigned_8 range 0 .. 2 ** 8 - 1;
   for Register_Index'Size use 8;
   subtype Character_Count is Natural;
   subtype Pixel_Count is Natural;
   subtype Scan_Line_Count is Natural;

   type Mode_Type is (alphanumeric, all_point_addressable, mode_invalid);
   type Alpha_Format is record
      Width : Character_Count;
      Height : Positive;
   end record;

   type Box_Size is record
      Width : Pixel_Count;
      Height : Pixel_Count;
   end record;

   type VGA_Mode is record
      vga_type     : Mode_Type;
      Colors       : Natural;
      AN_Format    : Alpha_Format;
      Box          : Box_Size;
      Pixel_Width  : Positive;
      Pixel_Height : Positive;
   end record;

   type VGA_Modes is array (Natural range 0 .. 16) of VGA_Mode;
   Modes : VGA_Modes := (
      0 => (alphanumeric, 16, (40, 25), (8, 8), 320, 200),
      1 => (alphanumeric, 16, (40, 25), (8, 14), 320, 350),
      2 => (alphanumeric, 16, (40, 25), (9, 16), 360, 400),
      3 => (alphanumeric, 16, (80, 25), (8, 8), 640, 200),
      4 => (alphanumeric, 16, (80, 25), (8, 14), 640, 350),
      5 => (alphanumeric, 16, (80, 25), (9, 16), 720, 400),
      6 => (all_point_addressable, 4, (40, 25), (8, 8), 320, 200),
      7 => (all_point_addressable, 2, (80, 25), (8, 8), 640, 200),
      8 => (alphanumeric, 0, (80, 25), (9, 14), 720, 350),
      9 => (alphanumeric, 0, (80, 25), (9, 16), 720, 400),
      10 => (all_point_addressable, 16,  (40, 25), (8, 8), 320, 200),
      11 => (all_point_addressable, 16,  (80, 25), (8, 8), 640, 200),
      12 => (all_point_addressable, 0,  (80, 25), (8, 1), 640, 350),
      13 => (all_point_addressable, 16,  (80, 25), (8, 1), 640, 350),
      14 => (all_point_addressable, 2,  (80, 30), (8, 1), 640, 480),
      15 => (all_point_addressable, 16,  (80, 30), (8, 1), 640, 480),
      16 => (all_point_addressable, 256,  (40, 25), (8, 8), 320, 200)
   );

   function Find_Mode (Width, Height, Color_Depth : Positive; graphic_mode : Mode_Type) return VGA_Mode;


   function Get_Frame_Buffer return System.Address;
   procedure Dump_Registers;

   procedure Set_Graphic_Mode (Width, Height, Color_Depth : Positive);
   procedure Set_Text_Mode (Width, Height, Color_Depth: Positive);
   --  procedure test (Width, Height : Positive);

   procedure Save_Frame_Buffer;
   procedure Restore_Frame_Buffer;  

   type vga_buffer is array (Positive range 1 .. 320 * 200) of aliased Unsigned_8
      with Pack => True;

   save_buffer_address : System.Address := System.Address'First;

   procedure load_palette (p : File_System.Path);

private
   -----------------------------------
   -- Miscellaneous Output Register --
   -----------------------------------
   type Clock_Select is (Clock_25M_640_320_PELs, Clock_28M_720_360_PELs, Clock_External);
   for Clock_Select use
     (Clock_25M_640_320_PELs => 2#00#, Clock_28M_720_360_PELs => 2#01#, Clock_External => 2#10#);
   type Vertical_Size is
     (Reserved,
      Size_400_Lines,
      Size_350_Lines,
      Size_480_Lines

     );
   for Vertical_Size use
     (Reserved => 2#00#, Size_400_Lines => 2#01#, Size_350_Lines => 2#10#, Size_480_Lines => 2#11#);
   type Miscellaneous_Output_Register is record
      IOS  : Boolean;
      ERAM : Boolean;
      CS   : Clock_Select;
      OE   : Boolean;
      Size : Vertical_Size;
   end record
   with Size => 8;
   for Miscellaneous_Output_Register use
     record
       IOS at 0 range 0 .. 0;
       ERAM at 0 range 1 .. 1;
       CS at 0 range 2 .. 3;
       OE at 0 range 5 .. 5;
       Size at 0 range 6 .. 7;
     end record;

   Miscellaneous_Output_Register_Read_Address  : constant x86.Port_IO.Port_Address := 16#03CC#;
   Miscellaneous_Output_Register_Write_Address : constant x86.Port_IO.Port_Address := 16#03C2#;

   function Read_Miscellaneous_Output_Register is new
     x86.Port_IO.Read_Port_8
       (Miscellaneous_Output_Register_Read_Address,
        Miscellaneous_Output_Register);
   procedure Write_Miscellaneous_Output_Register is new
     x86.Port_IO.Write_Port_8
       (Miscellaneous_Output_Register_Write_Address,
        Miscellaneous_Output_Register);


end VGA;
