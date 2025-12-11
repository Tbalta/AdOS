with Log;

package body Keyboard is
   package Logger renames Log.Serial_Logger;

   procedure Handle_Keyboard is
      use Keycode_Circular_Buffer;
      key : Keycode;
   begin
      if not Read_Status_Register.Output_Buffer_Status then
         return;
      end if;

      key := Read_Keycode;

      if not Key.Is_Released then
         return;
      end if;

      Logger.Log_Info ("Received: " & key'Image & " from keyboard");
      Push (Keycode_Buffer'Access, Key);

   end Handle_Keyboard;

   procedure init is
   begin
      Write_Command (Disable_Scanning_Command);

      Logger.Log_Info ("Sending Disable_Scan");
      while Read_Data_Register /= ACK loop
         null;
      end loop;

      Logger.Log_Info ("Sending Identify");
      Write_Command (Identify_Command);
      while Read_Data_Register /= ACK loop
         null;
      end loop;

      Logger.Log_Info ("Read :" & Read_Data_Register'Image & "From device");
   end init;

   function Get_Key_Code return Integer is
      use Keycode_Circular_Buffer;

      Last_Keycode : Dequeue_Result := Pop (Keycode_Buffer'Access);
   begin
      if Last_Keycode.Valid then
         return Integer (Last_Keycode.Value.Key);
      else
         return -1;
      end if;
   end Get_Key_Code;

end Keyboard;
