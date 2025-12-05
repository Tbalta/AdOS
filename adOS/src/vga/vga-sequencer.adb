------------------------------------------------------------------------------
--                             VGA-SEQUENCER                                --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with x86.Port_Io;
with SERIAL;
with Interfaces; use Interfaces;
with Ada.Unchecked_Conversion;

package body VGA.Sequencer is

   procedure Write_Data (Value : Data_Type) is
      procedure Write is new x86.Port_IO.Write_Port_8 (Data_Register_Address, Data_Type);
      function To_U8 is new Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Data_Type);
   begin
      Write_Address (Index);
      Write (Value);
      Register_Array (Index) := To_U8 (Value);
   end Write_Data;

   function Read_Data return Data_Type is
      function Read is new x86.Port_IO.Read_Port_8 (Data_Register_Address, Data_Type);
   begin
      Write_Address (Index);
      return Read;
   end Read_Data;

   procedure Dump_Sequencer_Registers is
   begin
      SERIAL.send_line ("");
      for I in Register_Array'Range loop
         SERIAL.send_string (I'image & "-> ");
         SERIAL.send_hex (Unsigned_32 (Register_Array (I)));
         SERIAL.send_line ("");
      end loop;
   end Dump_Sequencer_Registers;

   procedure Set_Sequencer_For_Mode (mode : VGA_mode)
   is
   begin
      Write_Reset_Register ((ASR => True, SR => True));
      Write_Clocking_Mode_Register ((D89 => mode.Box.Width = 8, SL => False, DC => False, SH4 => False, SO => False));

      --  In alphanumeric modes, the system writes the ASCII character
      --  code and attribute data to video memory maps 0 and 1,
      --  respectively. Memory map 2 contains the character font loaded by
      --  BIOS during an alphanumeric mode set. The font is used by the
      --  character generator to create the character image on the display.
      if mode.vga_type = alphanumeric then
         Write_Map_Mask_Register ((Map_0_Enable => True, Map_1_Enable => True, others => False));
      else
         Write_Map_Mask_Register ((others => True));
      end if;

      Write_Character_Map_Select_Register
        (To_Character_Map_Select_Register (Map_2_1st_8KB, Map_2_1st_8KB));

      -- In the alphanumeric modes, the programmer views maps 0 and 1 as
      --  a single buffer. 
      if mode.vga_type = alphanumeric then
         Write_Memory_Mode_Register ((Extended_Memory => True, Odd_Even => False, Chain_4 => False));
      else
         Write_Memory_Mode_Register ((Extended_Memory => True, Odd_Even => True, Chain_4 => True));
      end if;
   end Set_Sequencer_For_Mode;

   -----------
   -- Reset --
   -----------
   procedure Write_Reset_Register (Register : Reset_Register) is
      procedure Write is new Write_Data (Reset_Register, Reset);
   begin
      Write (Register);
   end Write_Reset_Register;

   function Read_Reset_Register return Reset_Register is
      function Read is new Read_Data (Reset_Register, Reset);
   begin
      return Read;
   end Read_Reset_Register;

   -------------------
   -- Clocking_Mode --
   -------------------
   procedure Write_Clocking_Mode_Register (Register : Clocking_Mode_Register) is
      procedure Write is new Write_Data (Clocking_Mode_Register, Clocking_Mode);
   begin
      Write (Register);
   end Write_Clocking_Mode_Register;

   function Read_Clocking_Mode_Register return Clocking_Mode_Register is
      function Read is new Read_Data (Clocking_Mode_Register, Clocking_Mode);
   begin
      return Read;
   end Read_Clocking_Mode_Register;

   --------------
   -- Map_Mask --
   --------------
   procedure Write_Map_Mask_Register (Register : Map_Mask_Register) is
      procedure Write is new Write_Data (Map_Mask_Register, Map_Mask);
   begin
      Write (Register);
   end Write_Map_Mask_Register;

   function Read_Map_Mask_Register return Map_Mask_Register is
      function Read is new Read_Data (Map_Mask_Register, Map_Mask);
   begin
      return Read;
   end Read_Map_Mask_Register;

   --------------------------
   -- Character_Map_Select --
   --------------------------
   function To_Character_Map_Select_Register
     (Map_A : Table_Location; Map_B : Table_Location) return Character_Map_Select_Register
   is
      type Table_Location_Breakdown is record
         LSB : Table_Location_LSB;
         MSB : Table_Location_MSB;
      end record
      with Size => 3;
      for Table_Location_Breakdown use
        record
          LSB at 0 range 0 .. 1;
          MSB at 0 range 2 .. 2;
        end record;
      function To_Breakdown is new
        Ada.Unchecked_Conversion (Source => Table_Location, Target => Table_Location_Breakdown);

      Map_A_Breakdown : Table_Location_Breakdown := To_Breakdown (Map_A);
      Map_B_Breakdown : Table_Location_Breakdown := To_Breakdown (Map_B);
   begin
      return
        (Map_A_MSB => Map_A_Breakdown.MSB,
         Map_B_MSB => Map_B_Breakdown.MSB,
         Map_A_LSB => Map_A_Breakdown.LSB,
         Map_B_LSB => Map_B_Breakdown.LSB);
   end To_Character_Map_Select_Register;

   procedure Write_Character_Map_Select_Register (Register : Character_Map_Select_Register) is
      procedure Write is new Write_Data (Character_Map_Select_Register, Character_Map_Select);
   begin
      Write (Register);
   end Write_Character_Map_Select_Register;

   function Read_Character_Map_Select_Register return Character_Map_Select_Register is
      function Read is new Read_Data (Character_Map_Select_Register, Character_Map_Select);
   begin
      return Read;
   end Read_Character_Map_Select_Register;

   -----------------
   -- Memory_Mode --
   -----------------
   procedure Write_Memory_Mode_Register (Register : Memory_Mode_Register) is
      procedure Write is new Write_Data (Memory_Mode_Register, Memory_Mode);
   begin
      Write (Register);
   end Write_Memory_Mode_Register;

   function Read_Memory_Mode_Register return Memory_Mode_Register is
      function Read is new Read_Data (Memory_Mode_Register, Memory_Mode);
   begin
      return Read;
   end Read_Memory_Mode_Register;

end VGA.Sequencer;
