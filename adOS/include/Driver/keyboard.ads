------------------------------------------------------------------------------
--                                 KEYBOARD                                 --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    PS2 keyboard driver                                                   --
------------------------------------------------------------------------------

with x86.Port_IO; use x86.Port_IO;
with Interfaces; use Interfaces;
with Circular_Buffer;

package Keyboard is
   pragma Preelaborate;
   generic package CB renames Circular_Buffer;


   procedure init;
   procedure Handle_Keyboard;
   function Get_Key_Code return Integer;


private

   type Status_Register_Format is record
      Output_Buffer_Status : Boolean;
      Input_Buffer_Status : Boolean;
      System_Flag : Boolean;
      Command_data : Boolean;
      Time_Out_Error : Boolean;
      Parity_error : Boolean;
   end record
      with Size => 8;

   for Status_Register_Format use record
      Output_Buffer_Status at 0 range 0 .. 0;
      Input_Buffer_Status at 0 range 1 .. 1;
      System_Flag at 0 range 2 .. 2;
      Command_data at 0 range 3 .. 3;
      Time_Out_Error at 0 range 6 .. 6;
      Parity_error at 0 range 7 .. 7;
   end record;

   type Keycode is record
      Key         :  Unsigned_7;
      Is_Released : Boolean := False;
   end record;

   for Keycode use record
      Key at 0 range 0 .. 6;
      Is_Released at 0 range 7 .. 7;
   end record;


   DATA_PORT : constant Port_Address := 16#60#;
   STATUS_REGISTER_PORT : constant Port_Address := 16#64#;
   COMMAND_REGISTER_PORT : constant Port_Address := 16#64#;

   Disable_Scanning_Command : constant Unsigned_8 := 16#F5#;
   Identify_Command         : constant Unsigned_8 := 16#F2#;
   ACK                      : constant Unsigned_8 := 16#FA#;

   procedure Write_Command is new Write_Port_8 (COMMAND_REGISTER_PORT, Unsigned_8);
   function Read_Data_Register is new Read_Port_8 (DATA_PORT, Unsigned_8);
   procedure Write_Data_Register is new Write_Port_8 (DATA_PORT, Unsigned_8);
   function Read_Status_Register is new Read_Port_8 (STATUS_REGISTER_PORT, Status_Register_Format);
   function Read_Keycode is new Read_Port_8 (DATA_PORT, Keycode);

   package Keycode_Circular_Buffer is new CB (256, Keycode);

   Keycode_Buffer : aliased Keycode_Circular_Buffer.Buffer_Type;

   


end Keyboard;