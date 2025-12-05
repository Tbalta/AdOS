with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with File_System.SERIAL;
with Log;
with Ada.Unchecked_Conversion;
with Programmable_Interval_Timer; use Programmable_Interval_Timer;

package body File_System.PIT is
   package Logger renames Log.Serial_Logger;

   ----------
   -- Open --
   ----------
   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error is
      FD : Driver_File_Descriptor_With_Error := DRIVER_FD_ERROR;
   begin
      if File_Path = "systick" then
         return SYSTICK_FD;
      end if;
   
      return DRIVER_FD_ERROR;
   end open;


   ----------
   -- Read --
   ----------
   function read (fd : Driver_File_Descriptor; Buffer : access Read_Type) return Integer is
   begin
      if fd /= SYSTICK_FD then
         Logger.Log_Error ("Invalid fd " & fd'Image);
         return -1;
      end if;

      --  Logger.Log_Info ("tick:" & Programmable_Interval_Timer.Get_Systick'Image);

      if Read_Type'Size /= Unsigned_32'Size then
         Logger.Log_Error ("Invalid write size expected: " & Integer (Unsigned_32'Size)'Image & "bits got: " & Integer (Read_Type'Size)'Image);
         return -1;
      end if;

      declare
         function To_U32 is new Ada.Unchecked_Conversion(Source => Integer, Target => Read_Type);
      begin
         Buffer.all := To_U32 (Programmable_Interval_Timer.Get_Systick);
      end;

      return Read_Type'Size / Storage_Unit;
   end read;

   -------------------
   -- SERIAL Seek --
   -------------------
   function seek (fd : Driver_File_Descriptor; offset : off_t; wh : whence) return off_t is
   begin
      return -1;
   end seek;

   ------------------
   -- SERIAL Close --
   ------------------
   function close (fd : Driver_File_Descriptor) return Integer is
   begin
      if fd /= SYSTICK_FD then
         return -1;
      end if;

      return 0;
   end close;
   
end File_System.PIT;
