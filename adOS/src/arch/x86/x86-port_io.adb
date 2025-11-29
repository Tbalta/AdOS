------------------------------------------------------------------------------
--                               X86.PORT_IO                                --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with System.Machine_Code;

package body x86.Port_IO is

   -----------
   -- Inb  --
   -----------
   function Inb (Port : Port_Address) return Read_Type is
      Data : Read_Type;
   begin
      pragma Assert (Read_Type'Size = 8);
      System.Machine_Code.Asm
        (Template => "inb %w1, %0",
         Inputs   => (Port_Address'Asm_Input ("Nd", Port)),
         Outputs  => (Read_Type'Asm_Output ("=a", Data)),
         Volatile => True);
      return Data;
   end Inb;

   -----------------
   -- Read_Port_8 --
   -----------------
   function Read_Port_8 return Read_Type is
      function Read_Port is new Inb (Read_Type);
   begin
      return Read_Port (Port);
   end Read_Port_8;

   ----------
   -- Outb --
   ----------
   procedure Outb (Port : Port_Address; Data : Write_Type) is
   begin
      pragma Assert (Write_Type'Size = 8);
      System.Machine_Code.Asm
        (Template => "outb %0, %w1",
         Inputs   =>
           (Write_Type'Asm_Input ("a", Data), Port_Address'Asm_Input ("Nd", Port)),
         Volatile => True);
   end Outb;

   ------------------
   -- Write_Port_8 --
   ------------------
   procedure Write_Port_8 (Data : Write_Type) is
      procedure Write_Port is new Outb (Write_Type);
   begin
      Write_Port (Port, Data);
   end Write_Port_8;

   ---------
   -- Inw --
   ---------
   function Inw (Port : Port_Address) return Read_Type is
      Data : Read_Type;
   begin
      pragma Assert (Read_Type'Size = 16);
      System.Machine_Code.Asm
        (Template => "inw %w1, %0",
         Inputs   => (Port_Address'Asm_Input ("Nd", Port)),
         Outputs  => (Read_Type'Asm_Output ("=a", Data)),
         Volatile => True);
      return Data;
   end Inw;

   ----------
   -- Outw --
   ----------
   procedure Outw (Port : Port_Address; Data : Write_Type) is
   begin
      pragma Assert (Write_Type'Size = 16);
      System.Machine_Code.Asm
        (Template => "outw %0, %w1",
         Inputs   =>
           (Write_Type'Asm_Input ("a", Data), Port_Address'Asm_Input ("Nd", Port)),
         Volatile => True);
   end Outw;
end x86.Port_IO;
