------------------------------------------------------------------------------
--                             VGA-ATTRIBUTE                                --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    register definition for attribute registers                           --
------------------------------------------------------------------------------
with System;
with x86.Port_IO;
with Interfaces; use Interfaces;
with VGA;

package VGA.Attribute is
   pragma Preelaborate;

   procedure Dump_Attribute_Registers;
   procedure Set_Attribute_For_Mode (mode : VGA_Mode);
   procedure Reset_Attribute_Register;

   -------------------------------
   -- Attribute Controller Type --
   -------------------------------
   type Attribute_Register_Index is new VGA.Register_Index range 0 .. 2 ** 6 - 1;
   for Attribute_Register_Index'Size use 8;
   procedure Select_Attribute_Register (Index : Attribute_Register_Index);


   -------------------------------
   -- Internal_Palette_Register --
   -------------------------------
   type Internal_Palette_Register is new Unsigned_6;
   for Internal_Palette_Register'Size use 8;
   subtype Internal_Palette_Register_Index is Attribute_Register_Index range 0 .. 2 ** 5 - 1;
   procedure Write_Internal_Palette_Register
     (Index : Internal_Palette_Register_Index; Register : Internal_Palette_Register);


   -------------------------------------
   -- Attribute_Mode_Control_Register --
   -------------------------------------
   type Attribute_Mode_Control_Register is record
      Graphic_Mode              : Boolean;
      Mono_Emulation            : Boolean;
      Enable_Line_Graphics      : Boolean;
      Enable_Blink              : Boolean;
      PEL_Panning_Compatibility : Boolean;
      PEL_Width                 : Boolean;
      P5_P4_Select              : Boolean;
   end record
   with Size => 8;
   for Attribute_Mode_Control_Register use
     record
       Graphic_Mode at 0 range 0 .. 0;
       Mono_Emulation at 0 range 1 .. 1;
       Enable_Line_Graphics at 0 range 2 .. 2;
       Enable_Blink at 0 range 3 .. 3;
       PEL_Panning_Compatibility at 0 range 5 .. 5;
       PEL_Width at 0 range 6 .. 6;
       P5_P4_Select at 0 range 7 .. 7;
     end record;
   procedure Write_Attribute_Mode_Control_Register (Register : Attribute_Mode_Control_Register);
   function Read_Attribute_Mode_Control_Register return Attribute_Mode_Control_Register;


   -----------------------------
   -- Overscan_Color_Register --
   -----------------------------
   type Overscan_Color_Register is new Unsigned_4;
   for Overscan_Color_Register'Size use 8;
   procedure Write_Overscan_Color_Register (Register : Overscan_Color_Register);
   function Read_Overscan_Color_Register return Overscan_Color_Register;


   ---------------------------------
   -- Color_Plane_Enable_Register --
   ---------------------------------
   type Color_Plane_Enable_Register is new Unsigned_8;
   for Color_Plane_Enable_Register'Size use 8;
   procedure Write_Color_Plane_Enable_Register (Register : Color_Plane_Enable_Register);
   function Read_Color_Plane_Enable_Register return Color_Plane_Enable_Register;


   -------------------------------------
   -- Horizontal_PEL_Panning_Register --
   -------------------------------------
   type Horizontal_PEL_Panning_Register is new Unsigned_4;
   for Horizontal_PEL_Panning_Register'Size use 8;
   procedure Write_Horizontal_PEL_Panning_Register (Register : Horizontal_PEL_Panning_Register);
   function Read_Horizontal_PEL_Panning_Register return Horizontal_PEL_Panning_Register;


   ---------------------------
   -- Color_Select_Register --
   ---------------------------
   type Color_Select_Register is record
      Select_Color_4 : Boolean;
      Select_Color_5 : Boolean;
      Select_Color_6 : Boolean;
      Select_Color_7 : Boolean;
   end record
   with Size => 8;
   for Color_Select_Register use
     record
       Select_Color_4 at 0 range 0 .. 0;
       Select_Color_5 at 0 range 1 .. 1;
       Select_Color_6 at 0 range 2 .. 2;
       Select_Color_7 at 0 range 3 .. 3;
     end record;
   procedure Write_Color_Select_Register (Register : Color_Select_Register);
   function Read_Color_Select_Register return Color_Select_Register;

private
   --------------------------------
   -- Attribute Register Address --
   --------------------------------
   Address_Register_Address    : constant x86.Port_IO.Port_Address := 16#03C0#;
   Read_Data_Register_Address  : constant x86.Port_IO.Port_Address := 16#03C1#;
   Write_Data_Register_Address : constant x86.Port_IO.Port_Address := 16#03C0#;
   procedure Write_Address is new
     x86.Port_IO.Write_Port_8 (Address_Register_Address, Attribute_Register_Index);


   --------------------
   -- Register Index --
   --------------------
   Attribute_Mode_Control : constant Attribute_Register_Index := 16#10#;
   Overscan_Color         : constant Attribute_Register_Index := 16#11#;
   Color_Plane_Enable     : constant Attribute_Register_Index := 16#12#;
   Horizontal_PEL_Panning : constant Attribute_Register_Index := 16#13#;
   Color_Select           : constant Attribute_Register_Index := 16#14#;


   -------------------------
   -- Register Write/Read --
   -------------------------
   generic
      type Data_Type is private;
      Index : Attribute_Register_Index;
   procedure Write_Register (Value : Data_Type);

   generic
      type Data_Type is private;
      Index : Attribute_Register_Index;
   function Read_Register return Data_Type;

   type Register_Value is array (Attribute_Register_Index range 0 .. 20) of Unsigned_8;
   Register_Array : Register_Value := (others => 0);

end VGA.Attribute;
