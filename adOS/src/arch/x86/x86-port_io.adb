with System.Machine_Code;
package body x86.Port_IO is
   ----------------------------------------------------------------------------
   --  Inb
   ----------------------------------------------------------------------------
   function Inb (Port : System.Address) return Interfaces.Unsigned_8 is
      Data : Interfaces.Unsigned_8;
   begin
      System.Machine_Code.Asm
        (Template => "inb %w1, %0",
         Inputs   => (System.Address'Asm_Input ("Nd", Port)),
         Outputs  => (Interfaces.Unsigned_8'Asm_Output ("=a", Data)),
         Volatile => True);
      return Data;
   end Inb;

   ----------------------------------------------------------------------------
   --  Outb
   ----------------------------------------------------------------------------
   procedure Outb (Port : System.Address; Data : Interfaces.Unsigned_8) is
   begin
      System.Machine_Code.Asm
        (Template => "outb %0, %w1",
         Inputs   =>
           (Interfaces.Unsigned_8'Asm_Input ("a", Data),
            System.Address'Asm_Input ("Nd", Port)),
         Volatile => True);
   end Outb;

   ----------------------------------------------------------------------------
   --  Inw
   ----------------------------------------------------------------------------
   function Inw (Port : System.Address) return Interfaces.Unsigned_16 is
      Data : Interfaces.Unsigned_16;
   begin
      System.Machine_Code.Asm
        (Template => "inw %w1, %0",
         Inputs   => (System.Address'Asm_Input ("Nd", Port)),
         Outputs  => (Interfaces.Unsigned_16'Asm_Output ("=a", Data)),
         Volatile => True);
      return Data;
   end Inw;

   ----------------------------------------------------------------------------
   --  Outw
   ----------------------------------------------------------------------------
   procedure Outw (Port : System.Address; Data : Interfaces.Unsigned_16) is
   begin
      System.Machine_Code.Asm
        (Template => "outw %0, %w1",
         Inputs   =>
           (Interfaces.Unsigned_16'Asm_Input ("a", Data),
            System.Address'Asm_Input ("Nd", Port)),
         Volatile => True);
   end Outw;
end x86.Port_IO;
