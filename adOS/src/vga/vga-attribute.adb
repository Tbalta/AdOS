with VGA.Attribute;
with x86.Port_Io;
with Ada.Unchecked_Conversion;
with SERIAL;
with Interfaces; use Interfaces;
package body VGA.Attribute is

   procedure Write_Data (Value : Data_Type)
   is
      procedure Write is new x86.Port_IO.Write_Port_8 (Write_Data_Register_Address, Data_Type);
      function To_U8 is new Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Data_Type);
   begin
      Write_Address (Index);
      Write (Value);
      SERIAL.send_hex (Unsigned_32 (To_U8 (Value)));
   end Write_Data;

   procedure Select_Internal_Palette_Register (Index : Attribute_Register)
   is
   begin
      Write_Address (Index);
   end Select_Internal_Palette_Register;

   function Read_Data return Data_Type
   is
      function Read is new x86.Port_IO.Read_Port_8 (Read_Data_Register_Address, Data_Type);
   begin
      Write_Address (Index);
      return Read;
   end Read_Data;
   
   -- Internal_Palette --
   procedure Write_Internal_Palette_Register (Index : Internal_Palette_Register_Index; Register : Internal_Palette_Register)
   is
      procedure Write is new Write_Data (Internal_Palette_Register, Index);
   begin
      Write (Register);
   end Write_Internal_Palette_Register;


   -- Attribute_Mode_Control --
   procedure Write_Attribute_Mode_Control_Register (Register : Attribute_Mode_Control_Register)
   is
      procedure Write is new Write_Data (Attribute_Mode_Control_Register, Attribute_Mode_Control);
   begin
      Write (Register);
   end Write_Attribute_Mode_Control_Register;

   function Read_Attribute_Mode_Control_Register return Attribute_Mode_Control_Register
   is
      function Read is new Read_Data (Attribute_Mode_Control_Register, Attribute_Mode_Control);
   begin
      return Read;
   end Read_Attribute_Mode_Control_Register;

   -- Overscan_Color --
   procedure Write_Overscan_Color_Register (Register : Overscan_Color_Register)
   is
      procedure Write is new Write_Data (Overscan_Color_Register, Overscan_Color);
   begin
      Write (Register);
   end Write_Overscan_Color_Register;

   function Read_Overscan_Color_Register return Overscan_Color_Register
   is
      function Read is new Read_Data (Overscan_Color_Register, Overscan_Color);
   begin
      return Read;
   end Read_Overscan_Color_Register;

   -- Color_Plane_Enable --
   procedure Write_Color_Plane_Enable_Register (Register : Color_Plane_Enable_Register)
   is
      procedure Write is new Write_Data (Color_Plane_Enable_Register, Color_Plane_Enable);
   begin
      Write (Register);
   end Write_Color_Plane_Enable_Register;

   function Read_Color_Plane_Enable_Register return Color_Plane_Enable_Register
   is
      function Read is new Read_Data (Color_Plane_Enable_Register, Color_Plane_Enable);
   begin
      return Read;
   end Read_Color_Plane_Enable_Register;

   -- Horizontal_PEL_Panning --
   procedure Write_Horizontal_PEL_Panning_Register (Register : Horizontal_PEL_Panning_Register)
   is
      procedure Write is new Write_Data (Horizontal_PEL_Panning_Register, Horizontal_PEL_Panning);
   begin
      Write (Register);
   end Write_Horizontal_PEL_Panning_Register;

   function Read_Horizontal_PEL_Panning_Register return Horizontal_PEL_Panning_Register
   is
      function Read is new Read_Data (Horizontal_PEL_Panning_Register, Horizontal_PEL_Panning);
   begin
      return Read;
   end Read_Horizontal_PEL_Panning_Register;

   -- Color_Select --
   procedure Write_Color_Select_Register (Register : Color_Select_Register)
   is
      procedure Write is new Write_Data (Color_Select_Register, Color_Select);
   begin
      Write (Register);
   end Write_Color_Select_Register;

   function Read_Color_Select_Register return Color_Select_Register
   is
      function Read is new Read_Data (Color_Select_Register, Color_Select);
   begin
      return Read;
   end Read_Color_Select_Register;



end VGA.Attribute;