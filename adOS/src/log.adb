with VGA;
package body Log is

   procedure Serial_Send_Line (Message : in String) is
   begin
      SERIAL.send_line (Serial.COM1, Message);
   end Serial_Send_Line;

   procedure Log_Message (Message : in String) is
   begin
      Serial_Logger.Log_Message (Message);
      VGA_Logger.Log_Message (Message);
   end Log_Message;

   procedure Log_Error (Error_Message : in String) is
   
   begin
      Serial_Logger.Log_Error (Error_Message);
      VGA_Logger.Log_Error (Error_Message);
   end Log_Error;

   procedure Log_Info (Info_Message : in String) is
   
   begin
      Serial_Logger.Log_Info (Info_Message);
      VGA_Logger.Log_Info (Info_Message);
   end Log_Info;

   procedure Log_Ok (Ok_Message : in String) is
   
   begin
      Serial_Logger.Log_Ok (Ok_Message);
      VGA_Logger.Log_Ok (Ok_Message);
   end Log_Ok;

   procedure Log_Warning (Warning_Message : in String) is
   begin
      Serial_Logger.Log_Warning (Warning_Message);
      VGA_Logger.Log_Warning (Warning_Message);
   end Log_Warning;

   procedure Panic (Panic_Message : in String) is
   begin
      -- VGA.Set_Text_Mode (80, 25, 16);
      Serial_Logger.Log_Error (Panic_Message);
      -- VGA_Logger.Log_Error (Panic_Message);
      while True loop
         null;
      end loop;
   end Panic;

   procedure Log_C_Char (c : Interfaces.C.char) is
   begin
      Serial_Logger.Log_Message ((1 => Interfaces.C.To_Ada (c)));
   end Log_C_Char;
end Log;
