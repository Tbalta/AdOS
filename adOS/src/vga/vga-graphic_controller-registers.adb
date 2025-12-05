------------------------------------------------------------------------------
--                          VGA-GRAPHIC_CONTROLLER                          --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with VGA.Graphic_Controller.Registers;
with x86.Port_Io;
with SERIAL;
with Interfaces; use Interfaces;
with Ada.Unchecked_Conversion;

package body VGA.Graphic_Controller.Registers is

   procedure Write_Data (Value : Data_Type) is
      procedure Write is new x86.Port_IO.Write_Port_8 (Data_Register_Address, Data_Type);
      function To_U8 is new Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Data_Type);
   begin
      Write_Address (Index);
      Write (Value);

      Register_Array (Index) := To_U8 (Value);
   end Write_Data;

   procedure Dump_Graphic_Controller_Registers is
   begin
      SERIAL.send_line ("");
      for I in Register_Array'Range loop
         SERIAL.send_string (I'image & "-> ");
         SERIAL.send_hex (Unsigned_32 (Register_Array (I)));
         SERIAL.send_line ("");
      end loop;
   end Dump_Graphic_Controller_Registers;


   function Read_Data return Data_Type is
      function Read is new x86.Port_IO.Read_Port_8 (Data_Register_Address, Data_Type);
   begin
      Write_Address (Index);
      return Read;
   end Read_Data;

   -- Set_Reset --
   procedure Write_Set_Reset_Register (Register : Set_Reset_Register) is
      procedure Write is new Write_Data (Set_Reset_Register, Set_Reset);
   begin
      Write (Register);
   end Write_Set_Reset_Register;

   function Read_Set_Reset_Register return Set_Reset_Register is
      function Read is new Read_Data (Set_Reset_Register, Set_Reset);
   begin
      return Read;
   end Read_Set_Reset_Register;

   -- Enable_Set_Reset --
   procedure Write_Enable_Set_Reset_Register (Register : Enable_Set_Reset_Register) is
      procedure Write is new Write_Data (Enable_Set_Reset_Register, Enable_Set_Reset);
   begin
      Write (Register);
   end Write_Enable_Set_Reset_Register;

   function Read_Enable_Set_Reset_Register return Enable_Set_Reset_Register is
      function Read is new Read_Data (Enable_Set_Reset_Register, Enable_Set_Reset);
   begin
      return Read;
   end Read_Enable_Set_Reset_Register;

   -- Color_Compare --
   procedure Write_Color_Compare_Register (Register : Color_Compare_Register) is
      procedure Write is new Write_Data (Color_Compare_Register, Color_Compare);
   begin
      Write (Register);
   end Write_Color_Compare_Register;

   function Read_Color_Compare_Register return Color_Compare_Register is
      function Read is new Read_Data (Color_Compare_Register, Color_Compare);
   begin
      return Read;
   end Read_Color_Compare_Register;

   -- Data_Rotate --
   procedure Write_Data_Rotate_Register (Register : Data_Rotate_Register) is
      procedure Write is new Write_Data (Data_Rotate_Register, Data_Rotate);
   begin
      Write (Register);
   end Write_Data_Rotate_Register;

   function Read_Data_Rotate_Register return Data_Rotate_Register is
      function Read is new Read_Data (Data_Rotate_Register, Data_Rotate);
   begin
      return Read;
   end Read_Data_Rotate_Register;

   -- Read_Map_Select --
   procedure Write_Read_Map_Select_Register (Register : Read_Map_Select_Register) is
      procedure Write is new Write_Data (Read_Map_Select_Register, Read_Map_Select);
   begin
      Write (Register);
   end Write_Read_Map_Select_Register;

   function Read_Read_Map_Select_Register return Read_Map_Select_Register is
      function Read is new Read_Data (Read_Map_Select_Register, Read_Map_Select);
   begin
      return Read;
   end Read_Read_Map_Select_Register;

   -- Graphics_Mode --
   procedure Write_Graphics_Mode_Register (Register : Graphics_Mode_Register) is
      procedure Write is new Write_Data (Graphics_Mode_Register, Graphics_Mode);
   begin
      Write (Register);
   end Write_Graphics_Mode_Register;

   function Read_Graphics_Mode_Register return Graphics_Mode_Register is
      function Read is new Read_Data (Graphics_Mode_Register, Graphics_Mode);
   begin
      return Read;
   end Read_Graphics_Mode_Register;

   -- Miscellaneous --
   procedure Write_Miscellaneous_Register (Register : Miscellaneous_Register) is
      procedure Write is new Write_Data (Miscellaneous_Register, Miscellaneous);
   begin
      Write (Register);
   end Write_Miscellaneous_Register;

   function Read_Miscellaneous_Register return Miscellaneous_Register is
      function Read is new Read_Data (Miscellaneous_Register, Miscellaneous);
   begin
      return Read;
   end Read_Miscellaneous_Register;

   -- Color_Dont_Care --
   procedure Write_Color_Dont_Care_Register (Register : Color_Dont_Care_Register) is
      procedure Write is new Write_Data (Color_Dont_Care_Register, Color_Dont_Care);
   begin
      Write (Register);
   end Write_Color_Dont_Care_Register;

   function Read_Color_Dont_Care_Register return Color_Dont_Care_Register is
      function Read is new Read_Data (Color_Dont_Care_Register, Color_Dont_Care);
   begin
      return Read;
   end Read_Color_Dont_Care_Register;

   -- Bit_Mask --
   procedure Write_Bit_Mask_Register (Register : Bit_Mask_Register) is
      procedure Write is new Write_Data (Bit_Mask_Register, Bit_Mask);
   begin
      Write (Register);
   end Write_Bit_Mask_Register;

   function Read_Bit_Mask_Register return Bit_Mask_Register is
      function Read is new Read_Data (Bit_Mask_Register, Bit_Mask);
   begin
      return Read;
   end Read_Bit_Mask_Register;

end VGA.Graphic_Controller.Registers;
