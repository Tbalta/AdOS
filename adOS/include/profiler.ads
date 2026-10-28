with Programmable_Interval_Timer;
package profiler is
   pragma Preelaborate;
   type Profiler_Data is record
      Total_Tick_Used : Programmable_Interval_Timer.Systick_Type;
      Number_Of_Calls : Natural;
      Current_Tick_Start : Programmable_Interval_Timer.Systick_Type;
   end record;


   procedure Start (Data : in out Profiler_Data);
   procedure Stop (Data : in out Profiler_Data);
   procedure Print (Data : Profiler_Data);


end profiler;