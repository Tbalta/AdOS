------------------------------------------------------------------------------
--                       Programmable_Interval_Timer                        --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    PIT register definition                                               --
------------------------------------------------------------------------------

with x86.Port_IO; use x86.Port_IO;
with Interfaces; use Interfaces;

package Programmable_Interval_Timer is
   pragma Preelaborate;

   procedure set_timer_period (ms : Positive);
   procedure Handle_Systick;
   function Get_Systick return Integer;


private
   Systick : Integer := 0;
   type Select_Counter is (Select_Counter_0, Select_Counter_1, Select_Counter_2, Read_Back_Command);
   for Select_Counter use (
      Select_Counter_0 => 2#00#,
      Select_Counter_1 => 2#01#,
      Select_Counter_2 => 2#10#,
      Read_Back_Command => 2#11#
   );

   type Read_Write_Format is (Counter_Latch_Command, LSB_Only, MSB_Only, LSB_Then_MSB);
   for Read_Write_Format use (
      Counter_Latch_Command => 2#00#,
      LSB_Only => 2#01#,
      MSB_Only => 2#10#,
      LSB_Then_MSB => 2#11#
   );

   type Mode_Format is (Interrupt_On_Terminal_Count, hardware_re_triggerable_one_shot, rate_generator, square_wave_generator, software_triggered_strobe, hardware_triggered_strobe);
   for Mode_Format use (
      Interrupt_On_Terminal_Count => 2#000#,
      hardware_re_triggerable_one_shot => 2#001#,
      rate_generator => 2#010#,
      square_wave_generator => 2#011#,
      software_triggered_strobe => 2#100#,
      hardware_triggered_strobe => 2#101#
   );


   type Control_Word_Format is record
      Counter    : Select_Counter;
      Read_Write : Read_Write_Format;
      Mode       : Mode_Format;
      BCD        : Boolean;
   end record;
   for Control_Word_Format use record
      BCD at 0 range 0 .. 0;
      Mode at 0 range 1 .. 3;
      Read_Write at 0 range 4 .. 5;
      Counter at 0 range 6 .. 7;
   end record;

   type Reload_Value_Format (Bit_Access : Boolean) is record
      case Bit_Access is
         when True =>
            LSB   : Unsigned_8;
            MSB   : Unsigned_8;
      when False =>
            Value : Unsigned_16;
         end case;
   end record;
   for Reload_Value_Format use record
      Value at 0 range 0 .. 15;
      LSB   at 0 range 0 .. 7;
      MSB   at 1 range 0 .. 7;
   end record;
   pragma Unchecked_Union (Reload_Value_Format);

   Control_Word_Register_Address : constant Port_Address := 16#43#;
   procedure Write_Control_Word is new Write_Port_8 (Control_Word_Register_Address, Control_Word_Format);

   Channel_0_Data_Port : constant Port_Address := 16#40#;
   procedure Write_Channel_0 is new Write_Port_8 (Channel_0_Data_Port, Unsigned_8);
   Channel_1_Data_Port : constant Port_Address := 16#41#;
   Channel_2_Data_Port : constant Port_Address := 16#42#;





end Programmable_Interval_Timer;