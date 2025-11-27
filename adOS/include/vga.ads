with x86.Port_IO;
with System;
with Interfaces; use Interfaces;
package VGA is
   pragma Pure;


   type Unsigned_2 is range 0 .. 2**2-1; 
   type Unsigned_3 is range 0 .. 2**3-1; 
   type Unsigned_4 is range 0 .. 2**4-1; 
   type Unsigned_5 is range 0 .. 2**5-1; 
   type Unsigned_6 is range 0 .. 2**6-1; 
   type Unsigned_10 is range 0 .. 2**10-1; 

   function Get_Frame_Buffer return System.Address;
   type Graphic_Mode is (
      VGA_320x200_4_Color,
      VGA_640x200_2_Color,
      VGA_640x350,
      VGA_640x480_2_Color
   );
   for Graphic_Mode use (
      VGA_320x200_4_Color => 16#4#,
      VGA_640x200_2_Color => 16#6#,
      VGA_640x350 => 16#F#,
      VGA_640x480_2_Color => 16#11#
   );

   procedure Switch_To_Mode (mode : Graphic_Mode);
   procedure enable_320x200x256;
   
   type Register_Index is new Unsigned_8 range 0 .. 2**8-1;
   for Register_Index'Size use 8;
   private
   -----------------------------------
   -- Miscellaneous Output Register --
   -----------------------------------
   type Clock_Select is (
      Clock_25M_640_320_PELs,
      Clock_28M_720_360_PELs,
      Clock_External
   );
   for Clock_Select use (
      Clock_25M_640_320_PELs => 2#00#,
      Clock_28M_720_360_PELs => 2#01#,
      Clock_External         => 2#10#
   );
   type Vertical_Size is (
      Reserved,
      Size_400_Lines,
      Size_350_Lines,
      Size_480_Lines

   );
   for Vertical_Size use (
      Reserved => 2#00#,
      Size_400_Lines => 2#01#,
      Size_350_Lines => 2#10#,
      Size_480_Lines => 2#11#
   );
   type Miscellaneous_Output_Register
 is
   record
      IOS : Boolean;
      ERAM : Boolean;
      CS : Clock_Select;
      Size : Vertical_Size;
   end record
      with Size => 8;
   for Miscellaneous_Output_Register use
   record
      IOS at 0 range 0 .. 0;
      ERAM at 0 range 1 .. 1;
      CS at 0 range 2 .. 3;
      Size at 0 range 6 .. 7;
      end record;

   Miscellaneous_Output_Register_Read_Address : constant System.Address := 16#03CC#;
   Miscellaneous_Output_Register_Write_Address : constant System.Address := 16#03C2#;

   function Read_Miscellaneous_Output_Register is new x86.Port_IO.Read_Port_8 (Miscellaneous_Output_Register_Read_Address, Miscellaneous_Output_Register);
   procedure Write_Miscellaneous_Output_Register is new x86.Port_IO.Write_Port_8 (Miscellaneous_Output_Register_Write_Address, Miscellaneous_Output_Register);


end VGA;