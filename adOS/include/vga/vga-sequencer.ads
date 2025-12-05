with System;
with x86.Port_IO;

package VGA.Sequencer is
   pragma Preelaborate;
   procedure Dump_Sequencer_Registers;
   --------------------
   -- Reset_Register --
   --------------------
   type Reset_Register is record
      ASR : Boolean;
      SR  : Boolean;
   end record
   with Size => 8;
   for Reset_Register use
     record
       ASR at 0 range 0 .. 0;
       SR at 0 range 1 .. 1;
     end record;
   procedure Write_Reset_Register (Register : Reset_Register);
   function Read_Reset_Register return Reset_Register;

   ----------------------------
   -- Clocking_Mode_Register --
   ----------------------------
   type Clocking_Mode_Register is record
      D89 : Boolean;
      SL  : Boolean;
      DC  : Boolean;
      SH4 : Boolean;
      SO  : Boolean;
   end record
   with Size => 8;
   for Clocking_Mode_Register use
     record
       D89 at 0 range 0 .. 0;
       SL at 0 range 2 .. 2;
       DC at 0 range 3 .. 3;
       SH4 at 0 range 4 .. 4;
       SO at 0 range 5 .. 5;
     end record;
   procedure Write_Clocking_Mode_Register (Register : Clocking_Mode_Register);
   function Read_Clocking_Mode_Register return Clocking_Mode_Register;

   ----------------------------
   -- Map_Mask_Register --
   ----------------------------
   type Map_Mask_Register is record
      Map_0_Enable : Boolean;
      Map_1_Enable : Boolean;
      Map_2_Enable : Boolean;
      Map_3_Enable : Boolean;
   end record
   with Size => 8;
   for Map_Mask_Register use
     record
       Map_0_Enable at 0 range 0 .. 0;
       Map_1_Enable at 0 range 1 .. 1;
       Map_2_Enable at 0 range 2 .. 2;
       Map_3_Enable at 0 range 3 .. 3;
     end record;
   procedure Write_Map_Mask_Register (Register : Map_Mask_Register);
   function Read_Map_Mask_Register return Map_Mask_Register;

   -----------------------------------
   -- Character_Map_Select_Register --
   -----------------------------------
   type Table_Location is
     (Map_2_1st_8KB,
      Map_2_3rd_8KB,
      Map_2_5th_8KB,
      Map_2_7th_8KB,
      Map_2_2nd_8KB,
      Map_2_4th_8KB,
      Map_2_6th_8KB,
      Map_2_8th_8KB);
   for Table_Location use
     (Map_2_1st_8KB => 2#000#,
      Map_2_3rd_8KB => 2#001#,
      Map_2_5th_8KB => 2#010#,
      Map_2_7th_8KB => 2#011#,
      Map_2_2nd_8KB => 2#100#,
      Map_2_4th_8KB => 2#101#,
      Map_2_6th_8KB => 2#110#,
      Map_2_8th_8KB => 2#111#);
   for Table_Location'Size use 3;

   type Table_Location_MSB is range 1 .. 1;
   type Table_Location_LSB is range 2 .. 2;

   type Character_Map_Select_Register is record
      Map_A_MSB : Table_Location_MSB;
      Map_B_MSB : Table_Location_MSB;
      Map_A_LSB : Table_Location_LSB;
      Map_B_LSB : Table_Location_LSB;
   end record
   with Size => 8;
   for Character_Map_Select_Register use
     record
       Map_B_LSB at 0 range 0 .. 1;
       Map_A_LSB at 0 range 2 .. 3;
       Map_B_MSB at 0 range 4 .. 4;
       Map_A_MSB at 0 range 5 .. 5;
     end record;
   function To_Character_Map_Select_Register
     (Map_A : Table_Location; Map_B : Table_Location) return Character_Map_Select_Register;
   procedure Write_Character_Map_Select_Register (Register : Character_Map_Select_Register);
   function Read_Character_Map_Select_Register return Character_Map_Select_Register;

   ----------------------------
   -- Memory_Mode_Register --
   ----------------------------
   type Memory_Mode_Register is record
      Extended_Memory : Boolean;
      Odd_Even        : Boolean;
      Chain_4         : Boolean;
   end record
   with Size => 8;
   for Memory_Mode_Register use
     record
       Extended_Memory at 0 range 1 .. 1;
       Odd_Even at 0 range 2 .. 2;
       Chain_4 at 0 range 3 .. 3;
     end record;
   procedure Write_Memory_Mode_Register (Register : Memory_Mode_Register);
   function Read_Memory_Mode_Register return Memory_Mode_Register;


private
   Address_Register_Address : constant x86.Port_IO.Port_Address := 16#03C4#;
   Data_Register_Address    : constant x86.Port_IO.Port_Address := 16#03C5#;
   type Sequencer_Registers is (Reset, Clocking_Mode, Map_Mask, Character_Map_Select, Memory_Mode);
   for Sequencer_Registers use
     (Reset                => 16#0#,
      Clocking_Mode        => 16#1#,
      Map_Mask             => 16#2#,
      Character_Map_Select => 16#3#,
      Memory_Mode          => 16#4#);
   for Sequencer_Registers'Size use 8;

   procedure Write_Address is new
     x86.Port_IO.Write_Port_8 (Address_Register_Address, Sequencer_Registers);

   generic
      type Data_Type is private;
      Index : Sequencer_Registers;
   procedure Write_Data (Value : Data_Type);
   generic
      type Data_Type is private;
      Index : Sequencer_Registers;
   function Read_Data return Data_Type;

   type Register_Value is array (Sequencer_Registers) of Unsigned_8;
   Register_Array : Register_Value := (others => 0);



end VGA.Sequencer;
