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

   type Unsigned_2 is range 0 .. 2 ** 2 - 1;
   type Unsigned_3 is range 0 .. 2 ** 3 - 1;
   type Unsigned_4 is range 0 .. 2 ** 4 - 1;
   type Unsigned_5 is range 0 .. 2 ** 5 - 1;
   type Unsigned_6 is range 0 .. 2 ** 6 - 1;
   type Unsigned_10 is range 0 .. 2 ** 10 - 1;

   function Get_Frame_Buffer return System.Address;
   procedure Dump_Registers;

   procedure Set_Graphic_Mode (Width, Height, Color_Depth : Positive);
   procedure Set_Text_Mode (Width, Height : Positive);

   procedure save_buffer;
   procedure restore_buffer;

   type Register_Index is new Unsigned_8 range 0 .. 2 ** 8 - 1;
   for Register_Index'Size use 8;
   subtype Character_Count is Natural;
   subtype Pixel_Count is Natural;
   subtype Scan_Line_Count is Natural;

   type vga_buffer is array (Positive range 1 .. 320 * 200) of aliased Unsigned_8
      with Pack => True;

   save_buffer_address : System.Address := System.Address'First;

   procedure load_palette (p : File_System.Path);

private
   procedure Reset_Attribute_Register;
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
