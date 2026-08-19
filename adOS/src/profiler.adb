with Loggers;
package body Profiler is
   package Logger renames Loggers.Serial_Logger;
   procedure Start (Data : in out Profiler_Data) is
   begin
      Data.Current_Tick_Start := Programmable_Interval_Timer.Get_Systick;
   end Start;

   procedure Stop (Data : in out Profiler_Data) is
      use type Programmable_Interval_Timer.Systick_Type;
      Tick_End : constant Programmable_Interval_Timer.Systick_Type := Programmable_Interval_Timer.Get_Systick;
   begin
      pragma Assert (Tick_End >= Data.Current_Tick_Start, "Systick wrapped around during profiling");
      pragma Assert (Data.Current_Tick_Start /= Tick_End, "Start and Stop called without any time passing");
      Data.Total_Tick_Used := Data.Total_Tick_Used + (Tick_End - Data.Current_Tick_Start);
      Data.Number_Of_Calls := Data.Number_Of_Calls + 1;
   end Stop;

   procedure Print (Data : Profiler_Data) is
      Average_Ticks : constant Float := Float (Data.Total_Tick_Used) / Float (Data.Number_Of_Calls);
   begin
      Logger.Log_Info ("Total Ticks Used: " & Programmable_Interval_Timer.Systick_Type'Image (Data.Total_Tick_Used));
      Logger.Log_Info ("Number of Calls: " & Natural'Image (Data.Number_Of_Calls));
      Logger.Log_Info ("Average Ticks per Call: " & Float'Image (Average_Ticks));
   end Print;

end profiler;