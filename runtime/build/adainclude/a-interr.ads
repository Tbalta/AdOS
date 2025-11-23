with System;
package Ada.Interrupts is
   pragma Pure;
   type Interrupt_ID is new Integer range 0 .. 255;
   type Parameterless_Handler is
      access protected procedure;

   function Is_Reserved (Interrupt : Interrupt_ID)
      return Boolean;

   function Is_Attached (Interrupt : Interrupt_ID)
      return Boolean;

   function Current_Handler (Interrupt : Interrupt_ID)
      return Parameterless_Handler;

   procedure Attach_Handler
      (New_Handler : Parameterless_Handler;
       Interrupt   : Interrupt_ID);

   procedure Exchange_Handler
      (Old_Handler : out Parameterless_Handler;
       New_Handler : Parameterless_Handler;
       Interrupt   : Interrupt_ID);

   procedure Detach_Handler
      (Interrupt : Interrupt_ID);

   function Reference (Interrupt : Interrupt_ID)
      return System.Address;

private
   --  not specified by the language
end Ada.Interrupts;
