------------------------------------------------------------------------------
--                              GENERIC_LOGGER                              --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

package body Generic_Logger is

   -----------------
   -- Log_Message --
   -----------------
   procedure Log_Message (Message : in String) is
   begin
      Print_Function (Message);
   end Log_Message;

   ---------------
   -- Log_Error --
   ---------------
   procedure Log_Error (Error_Message : in String) is
   begin
      Print_Function (ERROR & " " & Error_Message);
   end Log_Error;

   --------------
   -- Log_Info --
   --------------
   procedure Log_Info (Info_Message : in String) is
   begin
      Print_Function (INFO & " " & Info_Message);
   end Log_Info;

   ------------
   -- Log_Ok --
   ------------
   procedure Log_Ok (Ok_Message : in String) is
   begin
      Print_Function (OK & " " & Ok_Message);
   end Log_Ok;

   procedure Log_Warning (Warning_Message : in String) is
   begin
      Print_Function (WARNING & " " & Warning_Message);
   end Log_Warning;
end Generic_Logger;
