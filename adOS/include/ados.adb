with Loggers;
package body Ados is
   package Logger renames Loggers;

   procedure Stack_Check_Fail
   is
   begin
      Logger.Panic ("Stack check failed");
   end Stack_Check_Fail;
   
end Ados;