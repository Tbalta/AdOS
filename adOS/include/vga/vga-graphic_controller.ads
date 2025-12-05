------------------------------------------------------------------------------
--                          VGA-GRAPHIC_CONTROLLER                          --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    register definition for graphic controller registers                  --
------------------------------------------------------------------------------
with System;
with x86.Port_IO;

package VGA.Graphic_Controller is
   pragma Preelaborate;
   procedure Dump_Graphic_Controller_Registers;
   procedure Set_Graphic_Controller_For_Mode (mode : VGA_mode);
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
   for Set_Reset_Register use
     record
       SR0 at 0 range 0 .. 0;
       SR1 at 0 range 1 .. 1;
       SR2 at 0 range 2 .. 2;
       SR3 at 0 range 3 .. 3;
     end record;
   procedure Write_Set_Reset_Register (Register : Set_Reset_Register);
   function Read_Set_Reset_Register return Set_Reset_Register;

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
   for Enable_Set_Reset_Register use
     record
       ESR0 at 0 range 0 .. 0;
       ESR1 at 0 range 1 .. 1;
       ESR2 at 0 range 2 .. 2;
       ESR3 at 0 range 3 .. 3;
     end record;
   procedure Write_Enable_Set_Reset_Register (Register : Enable_Set_Reset_Register);
   function Read_Enable_Set_Reset_Register return Enable_Set_Reset_Register;

   ----------------------------
   -- Color_Compare_Register --
   ----------------------------
   type Color_Compare_Register is record
      CC0 : Boolean;
      CC1 : Boolean;
      CC2 : Boolean;
      CC3 : Boolean;
   end record
   with Size => 8;
   for Color_Compare_Register use
     record
       CC0 at 0 range 0 .. 0;
       CC1 at 0 range 1 .. 1;
       CC2 at 0 range 2 .. 2;
       CC3 at 0 range 3 .. 3;
     end record;
   procedure Write_Color_Compare_Register (Register : Color_Compare_Register);
   function Read_Color_Compare_Register return Color_Compare_Register;

   ----------------------------
   -- Data_Rotate_Register --
   ----------------------------
   type Data_Rotate_Function is (No_Function, Function_AND, Function_OR, Function_XOR);
   for Data_Rotate_Function use
     (No_Function => 2#00#, Function_AND => 2#01#, Function_OR => 2#10#, Function_XOR => 2#11#);

   type Data_Rotate_Register is record
      Rotate_Count    : Unsigned_3;
      Function_Select : Data_Rotate_Function;
   end record
   with Size => 8;
   for Data_Rotate_Register use
     record
       Rotate_Count at 0 range 0 .. 2;
       Function_Select at 0 range 3 .. 4;
     end record;
   procedure Write_Data_Rotate_Register (Register : Data_Rotate_Register);
   function Read_Data_Rotate_Register return Data_Rotate_Register;

   ----------------------------
   -- Read_Map_Select_Register --
   ----------------------------
   type Read_Map_Select_Register is new Unsigned_2;
   for Read_Map_Select_Register'Size use 8;
   procedure Write_Read_Map_Select_Register (Register : Read_Map_Select_Register);
   function Read_Read_Map_Select_Register return Read_Map_Select_Register;

   ----------------------------
   -- Graphics Mode Register --
   ----------------------------
   type Graphics_Mode_Register_Write_Mode is (Mode_0, Mode_1, Mode_2, Mode_3);
   for Graphics_Mode_Register_Write_Mode use
     (Mode_0 => 2#00#, Mode_1 => 2#01#, Mode_2 => 2#10#, Mode_3 => 2#11#);
   type Graphics_Mode_Register is record
      WM                  : Graphics_Mode_Register_Write_Mode;
      Read_Mode           : Boolean;
      Odd_Even            : Boolean;
      Shift_Register_Mode : Boolean;
      Color_Mode          : Boolean;
   end record
   with Size => 8;
   for Graphics_Mode_Register use
     record
       WM at 0 range 0 .. 1;
       Read_Mode at 0 range 3 .. 3;
       Odd_Even at 0 range 4 .. 4;
       Shift_Register_Mode at 0 range 5 .. 5;
       Color_Mode at 0 range 6 .. 6;
     end record;
   procedure Write_Graphics_Mode_Register (Register : Graphics_Mode_Register);
   function Read_Graphics_Mode_Register return Graphics_Mode_Register;

   ----------------------------
   -- Miscellaneous_Register --
   ----------------------------
   type Memory_Map_Addressing is (A0000_128KB, A0000_64KB, B0000_32KB, B8000_32KB);
   for Memory_Map_Addressing use
     (A0000_128KB => 2#00#, A0000_64KB => 2#01#, B0000_32KB => 2#10#, B8000_32KB => 2#11#);
   type Miscellaneous_Register is record
      Graphics_Mode : Boolean;
      Odd_Even      : Boolean;
      Memory_Map    : Memory_Map_Addressing;
   end record
   with Size => 8;
   for Miscellaneous_Register use
     record
       Graphics_Mode at 0 range 0 .. 0;
       Odd_Even at 0 range 1 .. 1;
       Memory_Map at 0 range 2 .. 3;
     end record;
   procedure Write_Miscellaneous_Register (Register : Miscellaneous_Register);
   function Read_Miscellaneous_Register return Miscellaneous_Register;



   ----------------------------
   -- Color_Dont_Care_Register --
   ----------------------------
   type Color_Dont_Care_Register is record
      M0X : Boolean;
      M1X : Boolean;
      M2X : Boolean;
      M3X : Boolean;
   end record
   with Size => 8;
   for Color_Dont_Care_Register use
     record
       M0X at 0 range 0 .. 0;
       M1X at 0 range 1 .. 1;
       M2X at 0 range 2 .. 2;
       M3X at 0 range 3 .. 3;
     end record;
   procedure Write_Color_Dont_Care_Register (Register : Color_Dont_Care_Register);
   function Read_Color_Dont_Care_Register return Color_Dont_Care_Register;

   ----------------------------
   -- Bit_Mask_Register --
   ----------------------------
   type Bit_Mask_Register is array (Natural range 0 .. 7) of Boolean;
   for Bit_Mask_Register'Component_Size use 1;
   for Bit_Mask_Register'Size use 8;
   procedure Write_Bit_Mask_Register (Register : Bit_Mask_Register);
   function Read_Bit_Mask_Register return Bit_Mask_Register;



private
   Address_Register_Address : constant x86.Port_IO.Port_Address := 16#03CE#;
   Data_Register_Address    : constant x86.Port_IO.Port_Address := 16#03CF#;
   type Graphic_Controller_Register is
     (Set_Reset,
      Enable_Set_Reset,
      Color_Compare,
      Data_Rotate,
      Read_Map_Select,
      Graphics_Mode,
      Miscellaneous,
      Color_Dont_Care,
      Bit_Mask);
   for Graphic_Controller_Register use
     (Set_Reset        => 16#0#,
      Enable_Set_Reset => 16#1#,
      Color_Compare    => 16#2#,
      Data_Rotate      => 16#3#,
      Read_Map_Select  => 16#4#,
      Graphics_Mode    => 16#5#,
      Miscellaneous    => 16#6#,
      Color_Dont_Care  => 16#7#,
      Bit_Mask         => 16#8#);
   for Graphic_Controller_Register'Size use 8;
   ----------------------
   -- Address Register --
   ----------------------

   procedure Write_Address is new
     x86.Port_IO.Write_Port_8 (Address_Register_Address, Graphic_Controller_Register);

   generic
      type Data_Type is private;
      Index : Graphic_Controller_Register;
   procedure Write_Data (Value : Data_Type);
   generic
      type Data_Type is private;
      Index : Graphic_Controller_Register;
   function Read_Data return Data_Type;

   type Register_Value is array (Graphic_Controller_Register) of Unsigned_8;
   Register_Array : Register_Value := (others => 0);


end VGA.Graphic_Controller;
