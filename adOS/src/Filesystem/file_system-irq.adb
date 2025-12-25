with System;                      use System;
with System.Storage_Elements;     use System.Storage_Elements;
with File_System.SERIAL;
with Loggers;
with Ada.Unchecked_Conversion;
with Programmable_Interval_Timer; use Programmable_Interval_Timer;
with Keyboard;

package body File_System.IRQ is
   package Logger renames Loggers.Serial_Logger;

   ----------
   -- Open --
   ----------
   function open (File_Path : Path; flag : Integer) return Driver_File_Descriptor_With_Error is
      FD : Driver_File_Descriptor_With_Error := DRIVER_FD_ERROR;
   begin
      if File_Path = "systick" then
         return SYSTICK_FD;
      end if;

      if File_Path = "keyboard" then
         return KEYBOARD_FD;
      end if;

      return DRIVER_FD_ERROR;
   end open;


   ----------
   -- Read --
   ----------
   function read (fd : Driver_File_Descriptor; Buffer : access Read_Type) return Integer is
   begin
      if fd /= SYSTICK_FD and then fd /= KEYBOARD_FD then
         Logger.Log_Error ("Invalid fd " & fd'Image);
         return -1;
      end if;

      if Read_Type'Size /= Integer'Size or else Read_Type'Object_Size /= Integer'Object_Size then
         Logger.Log_Error
           ("Invalid write size expected: "
            & Integer (Integer'Size)'Image
            & "bits got: "
            & Integer (Read_Type'Size)'Image);
         return -1;
      end if;

      declare
         pragma Assert (Read_Type'Size = Integer'Size);

         pragma Warnings (Off, "types for unchecked conversion have different sizes");
         function To_Read_Type is new Ada.Unchecked_Conversion (Source => Integer, Target => Read_Type);
         pragma Warnings (On, "types for unchecked conversion have different sizes");
         begin
         case fd is
            when SYSTICK_FD =>
               --  Logger.Log_Info ("Read_Systick " & Programmable_Interval_Timer.Get_Systick'Image);
               Buffer.all := To_Read_Type (Programmable_Interval_Timer.Get_Systick);

            when KEYBOARD_FD =>
               Buffer.all := To_Read_Type (Keyboard.Get_Key_Code);

            when others =>
               Logger.Log_Info ("Invalid fd");
               Buffer.all := To_Read_Type ((-1));
         end case;
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

end File_System.IRQ;
