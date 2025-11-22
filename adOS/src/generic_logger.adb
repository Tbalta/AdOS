package body Generic_Logger is
   procedure Log_Message (Message : in String) is
   begin
      Print_Function (Message);
   end Log_Message;

   procedure Log_Error (Error_Message : in String) is
   begin
      Print_Function (ERROR & " " & Error_Message);
   end Log_Error;

   procedure Log_Info (Info_Message : in String) is
   begin
      Print_Function (INFO & " " & Info_Message);
   end Log_Info;

   procedure Log_Ok (Ok_Message : in String) is
   begin
      Print_Function (OK & " " & Ok_Message);
   end Log_Ok;
end Generic_Logger;
