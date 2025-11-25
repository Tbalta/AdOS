with System;
with x86.Port_IO;
package VGA.Graphic_Controller is
   pragma Pure;
   ------------------------
   -- Set_Reset_Register --
   ------------------------
   type Set_Reset_Register is record
      SR0 : Boolean;
      SR1 : Boolean;
      SR2 : Boolean;
      SR3 : Boolean;
   end record
      with Size => 8;
   for Set_Reset_Register use record
      SR0 at 0 range 0 .. 0;
      SR1 at 0 range 1 .. 1;
      SR2 at 0 range 2 .. 2;
      SR3 at 0 range 3 .. 3;
   end record;
   procedure Write_Set_Reset_Register (Register : Set_Reset_Register);
   function  Read_Set_Reset_Register return Set_Reset_Register;

   ----------------------------
   -- Graphics Mode Register --
   ----------------------------
   type Graphics_Mode_Register_Write_Mode is (Mode_0, Mode_1, Mode_2, Mode_3);
   for Graphics_Mode_Register_Write_Mode use 
      (
         Mode_0 => 2#00#,
         Mode_1 => 2#01#,
         Mode_2 => 2#10#,
         Mode_3 => 2#11#
      );
   type Graphics_Mode_Register is
      record
         WM : Graphics_Mode_Register_Write_Mode;
         Read_Mode : Boolean;
         Odd_Even : Boolean;
         Shift_Register_Mode : Boolean;
         Color_Mode : Boolean;
      end record
         with Size => 8;
   for Graphics_Mode_Register use record
      WM at 0 range 0 .. 1;
      Read_Mode at 0 range 3 .. 3;
      Odd_Even at 0 range 4 .. 4;
      Shift_Register_Mode at 0 range 5 .. 5;
      Color_Mode at 0 range 6 .. 6;
      end record;
   procedure Write_Graphics_Mode_Register (Register : Graphics_Mode_Register);
   function  Read_Graphics_Mode_Register return Graphics_Mode_Register;

   -------------------------------
   -- Enable_Set_Reset_Register --
   -------------------------------
   type Enable_Set_Reset_Register is record
      ESR0 : Boolean;
      ESR1 : Boolean;
      ESR2 : Boolean;
      ESR3 : Boolean;
   end record
      with Size => 8;
   for Enable_Set_Reset_Register use record
      ESR0 at 0 range 0 .. 0; 
      ESR1 at 0 range 1 .. 1; 
      ESR2 at 0 range 2 .. 2; 
      ESR3 at 0 range 3 .. 3; 
   end record;
   procedure Write_Enable_Set_Reset_Register (Register : Enable_Set_Reset_Register);
   function  Read_Enable_Set_Reset_Register return Enable_Set_Reset_Register;



private
   Address_Register_Address : constant System.Address := 16#03CE#;
   Data_Register_Address    : constant System.Address := 16#03CF#;
   type Graphic_Controller_Register is (
      Set_Reset,
      Enable_Set_Reset,
      Color_Compare,
      Data_Rotate,
      Read_Map_Select,
      Graphics_Mode,
      Miscellaneous,
      Color_Dont_Care,
      Bit_Mask);
   for Graphic_Controller_Register use (
      Set_Reset => 16#0#,
      Enable_Set_Reset => 16#1#,
      Color_Compare => 16#2#,
      Data_Rotate => 16#3#,
      Read_Map_Select => 16#4#,
      Graphics_Mode => 16#5#,
      Miscellaneous => 16#6#,
      Color_Dont_Care => 16#7#,
      Bit_Mask => 16#8#);
   ----------------------
   -- Address Register --
   ----------------------
   type Address_Register is record
      Index : Graphic_Controller_Register;
   end record
      with Size => 8;
   for Address_Register use record
      Index at 0 range 0 .. 3;
   end record;
   
   procedure Write_Address is new x86.Port_IO.Write_Port_8 (Address_Register_Address, Address_Register);

   generic
      type Data_Type is private;
      Index : Graphic_Controller_Register;
   procedure Write_Data (Value : Data_Type);
   generic
      type Data_Type is private;
      Index : Graphic_Controller_Register;
   function Read_Data return Data_Type;



end VGA.Graphic_Controller;