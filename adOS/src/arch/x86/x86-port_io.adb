with System.Machine_Code;

package body x86.Port_IO is
   ----------------------------------------------------------------------------
   --  Inb
   ----------------------------------------------------------------------------
   --  function Inb (Port : System.Address) return Interfaces.Unsigned_8 is
   --     Data : Interfaces.Unsigned_8;
   --  begin
   --     System.Machine_Code.Asm
   --       (Template => "inb %w1, %0",
   --        Inputs   => (System.Address'Asm_Input ("Nd", Port)),
   --        Outputs  => (Interfaces.Unsigned_8'Asm_Output ("=a", Data)),
   --        Volatile => True);
   --     return Data;
   --  end Inb;

   ----------------------------------------------------------------------------
   --  Inb
   ----------------------------------------------------------------------------
   function Inb (Port : System.Address) return Read_Type is
      Data : Read_Type;
   begin
      pragma Assert (Read_Type'Size = 8);
      System.Machine_Code.Asm
        (Template => "inb %w1, %0",
         Inputs   => (System.Address'Asm_Input ("Nd", Port)),
         Outputs  => (Read_Type'Asm_Output ("=a", Data)),
         Volatile => True);
      return Data;
   end Inb;

   ----------------------------------------------------------------------------
   --  Outb
   ----------------------------------------------------------------------------
   procedure Outb (Port : System.Address; Data : Write_Type) is
   begin
      pragma Assert (Write_Type'Size = 8);
      System.Machine_Code.Asm
        (Template => "outb %0, %w1",
         Inputs   =>
           (Write_Type'Asm_Input ("a", Data), System.Address'Asm_Input ("Nd", Port)),
         Volatile => True);
   end Outb;

   ----------------------------------------------------------------------------
   --  Inw
   ----------------------------------------------------------------------------
   function Inw (Port : System.Address) return Read_Type is
      Data : Read_Type;
   begin
      pragma Assert (Read_Type'Size = 16);
      System.Machine_Code.Asm
        (Template => "inw %w1, %0",
         Inputs   => (System.Address'Asm_Input ("Nd", Port)),
         Outputs  => (Read_Type'Asm_Output ("=a", Data)),
         Volatile => True);
      return Data;
   end Inw;

   ----------------------------------------------------------------------------
   --  Outw
   ----------------------------------------------------------------------------
   procedure Outw (Port : System.Address; Data : Write_Type) is
   begin
      pragma Assert (Write_Type'Size = 16);
      System.Machine_Code.Asm
        (Template => "outw %0, %w1",
         Inputs   =>
           (Write_Type'Asm_Input ("a", Data), System.Address'Asm_Input ("Nd", Port)),
         Volatile => True);
   end Outw;
end x86.Port_IO;
