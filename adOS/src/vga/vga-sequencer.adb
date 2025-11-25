with VGA.Sequencer;
with x86.Port_Io;
with Ada.Unchecked_Conversion;
package body VGA.Sequencer is

   procedure Write_Data (Value : Data_Type)
   is
      procedure Write is new x86.Port_IO.Write_Port_8 (Data_Register_Address, Data_Type);
   begin
      Write_Address (Index);
      Write (Value);
   end Write_Data;

   function Read_Data return Data_Type
   is
      function Read is new x86.Port_IO.Read_Port_8 (Data_Register_Address, Data_Type);
   begin
      Write_Address (Index);
      return Read;
   end Read_Data;

   -----------
   -- Reset --
   -----------
   procedure Write_Reset_Register (Register : Reset_Register)
   is
      procedure Write is new Write_Data (Reset_Register, Reset);
   begin
      Write (Register);
   end Write_Reset_Register;

   function Read_Reset_Register return Reset_Register
   is
      function Read is new Read_Data (Reset_Register, Reset);
   begin
      return Read;
   end Read_Reset_Register;

   -------------------
   -- Clocking_Mode --
   -------------------
   procedure Write_Clocking_Mode_Register (Register : Clocking_Mode_Register)
   is
      procedure Write is new Write_Data (Clocking_Mode_Register, Clocking_Mode);
   begin
      Write (Register);
   end Write_Clocking_Mode_Register;

   function Read_Clocking_Mode_Register return Clocking_Mode_Register
   is
      function Read is new Read_Data (Clocking_Mode_Register, Clocking_Mode);
   begin
      return Read;
   end Read_Clocking_Mode_Register;

   --------------
   -- Map_Mask --
   --------------
   procedure Write_Map_Mask_Register (Register : Map_Mask_Register)
   is
      procedure Write is new Write_Data (Map_Mask_Register, Map_Mask);
   begin
      Write (Register);
   end Write_Map_Mask_Register;

   function Read_Map_Mask_Register return Map_Mask_Register
   is
      function Read is new Read_Data (Map_Mask_Register, Map_Mask);
   begin
      return Read;
   end Read_Map_Mask_Register;

   --------------------------
   -- Character_Map_Select --
   --------------------------
   function To_Character_Map_Select_Register (Map_A : Table_Location; Map_B : Table_Location) return Character_Map_Select_Register
   is
      type Table_Location_Breakdown is record
         LSB : Table_Location_LSB;
         MSB : Table_Location_MSB;
      end record
         with Size => 3;
      for Table_Location_Breakdown use record
         LSB at 0 range 0 .. 1;
         MSB at 0 range 2 .. 2;
      end record;
   function To_Breakdown is new
     Ada.Unchecked_Conversion (Source => Table_Location, Target => Table_Location_Breakdown);

     Map_A_Breakdown : Table_Location_Breakdown := To_Breakdown (Map_A);
     Map_B_Breakdown : Table_Location_Breakdown := To_Breakdown (Map_B);
   begin
      return (Map_A_MSB => Map_A_Breakdown.MSB,
              Map_B_MSB => Map_B_Breakdown.MSB,
              Map_A_LSB => Map_A_Breakdown.LSB,
              Map_B_LSB => Map_B_Breakdown.LSB);
   end To_Character_Map_Select_Register;


   procedure Write_Character_Map_Select_Register (Register : Character_Map_Select_Register)
   is
      procedure Write is new Write_Data (Character_Map_Select_Register, Character_Map_Select);
   begin
      Write (Register);
   end Write_Character_Map_Select_Register;


   function Read_Character_Map_Select_Register return Character_Map_Select_Register
   is
      function Read is new Read_Data (Character_Map_Select_Register, Character_Map_Select);
   begin
      return Read;
   end Read_Character_Map_Select_Register;

   -----------------
   -- Memory_Mode --
   -----------------
   procedure Write_Memory_Mode_Register (Register : Memory_Mode_Register)
   is
      procedure Write is new Write_Data (Memory_Mode_Register, Memory_Mode);
   begin
      Write (Register);
   end Write_Memory_Mode_Register;

   function Read_Memory_Mode_Register return Memory_Mode_Register
   is
      function Read is new Read_Data (Memory_Mode_Register, Memory_Mode);
   begin
      return Read;
   end Read_Memory_Mode_Register;

end VGA.Sequencer;