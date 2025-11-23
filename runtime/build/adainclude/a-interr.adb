package body Ada.Interrupts is

   function Is_Reserved (Interrupt : Interrupt_ID)
      return Boolean is
   pragma Unreferenced (Interrupt);
   begin
      return False;
   end Is_Reserved;

   function Is_Attached (Interrupt : Interrupt_ID)
      return Boolean is
   pragma Unreferenced (Interrupt);
   begin
      return False;
   end Is_Attached;

   function Current_Handler (Interrupt : Interrupt_ID)
      return Parameterless_Handler is
   pragma Unreferenced (Interrupt);
   begin
      return null;
   end Current_Handler;

   procedure Attach_Handler
      (New_Handler : Parameterless_Handler;
       Interrupt   : Interrupt_ID) is null;

   procedure Exchange_Handler
      (Old_Handler : out Parameterless_Handler;
       New_Handler : Parameterless_Handler;
       Interrupt   : Interrupt_ID) is null;

   procedure Detach_Handler
      (Interrupt : Interrupt_ID) is null;

   function Reference (Interrupt : Interrupt_ID)
      return System.Address is
   pragma Unreferenced (Interrupt);
   begin
      return System.Null_Address;
   end Reference;

end Ada.Interrupts;
