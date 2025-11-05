generic
   with procedure Print_Function (Message : in String);
package Generic_Logger is 
   pragma Preelaborate;
   
   ESC   : constant Character := Character'Val (16#1B#);
   RED   : constant String    := ESC & "[31m";
   GREEN : constant String    := ESC & "[32m";
   YELLOW: constant String    := ESC & "[33m";
   BLUE  : constant String    := ESC & "[34m";
   RESET : constant String    := ESC & "[0m";

   ERROR : constant String := RED   & "[ERROR]" & RESET;
   INFO  : constant String := BLUE  & "[INFO ]" & RESET;
   OK    : constant String := GREEN & "[OK   ]" & RESET;
   


   procedure Log_Message (Message : in String);
   procedure Log_Error (Error_Message : in String);
   procedure Log_Info (Info_Message : in String);
   procedure Log_Ok (Ok_Message : in String);
end Generic_Logger;