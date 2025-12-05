------------------------------------------------------------------------------
--                       Programmable_Interval_Timer                        --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Log;
package body Programmable_Interval_Timer is
   package Logger renames Log.Serial_Logger;

   procedure Set_Timer_Period (ms : Positive)
   is
      PIT_Frequency_Hz : constant Float := 1193182.0;
      Reload_Value : Reload_Value_Format := (Value => Unsigned_16 (Float'Rounding (PIT_Frequency_Hz * Float (ms) / 1000.0)), Bit_Access => False);
   begin
      Logger.Log_Info ("Reload_Value " & Reload_Value.Value'Image);
      Write_Control_Word ((Counter    => Select_Counter_0,
                           Read_Write => LSB_Then_MSB,
                           Mode       => square_wave_generator,
                           BCD        => False));
      Write_Channel_0 (Reload_Value.LSB);
      Write_Channel_0 (Reload_Value.MSB);

   end Set_Timer_Period;

   procedure Handle_Systick is
   begin
      Systick := Systick + 1;

      if Systick mod 100 = 0 then
         Logger.Log_Info ("Systick: " & Integer (Systick / 100)'Image);
      end if;
   end Handle_Systick;

   function Get_Systick return Integer is
   begin
      return Systick;
   end Get_Systick;

end Programmable_Interval_Timer;