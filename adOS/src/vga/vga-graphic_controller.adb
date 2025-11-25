with VGA.Graphic_Controller;
with x86.Port_Io;
package body VGA.Graphic_Controller is

   procedure Write_Data (Value : Data_Type)
   is
      procedure Write is new x86.Port_IO.Write_Port_8 (Data_Register_Address, Data_Type);
   begin
      Write_Address ((Index => Index));
      Write (Value);
   end Write_Data;

   function Read_Data return Data_Type
   is
      function Read is new x86.Port_IO.Read_Port_8 (Data_Register_Address, Data_Type);
   begin
      Write_Address ((Index => Index));
      return Read;
   end Read_Data;

   ---------------
   -- Set_Reset --
   ---------------
   procedure Write_Set_Reset_Register (Register : Set_Reset_Register)
   is
      procedure Write is new Write_Data (Set_Reset_Register, Set_Reset);
   begin
      Write (Register);
   end Write_Set_Reset_Register;

   function Read_Set_Reset_Register return Set_Reset_Register
   is
      function Read is new Read_Data (Set_Reset_Register, Set_Reset);
   begin
      Write_Address ((Index => Set_Reset));
      return Read;
   end Read_Set_Reset_Register;

   -------------------
   -- Graphics_Mode --
   -------------------
   procedure Write_Graphics_Mode_Register (Register : Graphics_Mode_Register)
   is
      procedure Write is new Write_Data (Graphics_Mode_Register, Graphics_Mode);
   begin
      Write (Register);
   end Write_Graphics_Mode_Register;

   function Read_Graphics_Mode_Register return Graphics_Mode_Register
   is
      function Read is new Read_Data (Graphics_Mode_Register, Graphics_Mode);
   begin
      Write_Address ((Index => Graphics_Mode));
      return Read;
   end Read_Graphics_Mode_Register;
   
   ---------------------
   -- Enable_Set_Reset --
   ---------------------
   procedure Write_Enable_Set_Reset_Register (Register : Enable_Set_Reset_Register)
   is
      procedure Write is new Write_Data (Enable_Set_Reset_Register, Enable_Set_Reset);
   begin
      Write (Register);
   end Write_Enable_Set_Reset_Register;

   function Read_Enable_Set_Reset_Register return Enable_Set_Reset_Register
   is
      function Read is new Read_Data (Enable_Set_Reset_Register, Enable_Set_Reset);
   begin
      Write_Address ((Index => Enable_Set_Reset));
      return Read;
   end Read_Enable_Set_Reset_Register;

end VGA.Graphic_Controller;