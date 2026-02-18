------------------------------------------------------------------------------
--                                   PIC                                    --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Interfaces; use Interfaces;
with Loggers;

package body pic is
   package Logger renames Loggers;

   ----------
   -- Init --
   ----------
   procedure Init is
      Master_Interrupt_Offset : constant Unsigned_8 := 16#20#;
      Slave_Interrupt_Offset  : constant Unsigned_8 := 16#28#;
      Slave_Index             : constant := 2;
   begin
      -- Master
      Write_Master_ICW1 ((IC4_Needed   => True,
                   Single_Mode  => False,
                   ADI          => Interval_Of_8,
                   Trigger_Mode => Edge_Triggered,
                   others => <>));
      Write_Master_ICW2 ((Interrupt_Address_T7_T3 => Unsigned_5 (Shift_Right (Master_Interrupt_Offset, 3))));
      Write_Master_ICW3 ((Slave_Index => True, others => False));
      Write_Master_ICW4 ((Is_8086                  => True,
                          Auto_EOI_Enable          => False,
                          Buffer_Mode              => Non_Buffered,
                          Fully_Nested_Mode_Enable => False));

      -- Slave
      Write_Slave_ICW1 ((IC4_Needed   => True,
                         Single_Mode  => False,
                         ADI          => Interval_Of_8,
                         Trigger_Mode => Edge_Triggered,
                         others => <>));
      Write_Slave_ICW2 ((Interrupt_Address_T7_T3 => Unsigned_5 (Shift_Right (Slave_Interrupt_Offset, 3))));
      Write_Slave_ICW3 ((Slave_Index => Slave_Index));
      Write_Slave_ICW4 ((Is_8086                  => True,
                         Auto_EOI_Enable          => False,
                         Buffer_Mode              => Non_Buffered,
                         Fully_Nested_Mode_Enable => False));

      -- Unmask interrupt
      Write_Master_OCW1 ((Slave_Index => CHANNEL_ENABLED, others => CHANNEL_MASKED));
      Write_Slave_OCW1 ((others => CHANNEL_MASKED));
   end Init;

   procedure Clear_Mask (irq : IRQ_Line) is
      Port  : PIT_PORT;
      IRQ_V : IRQ_Line := irq;
      OCW1 : OCW1_Format;

      function Read_OCW1 is new x86.Port_IO.Inb (OCW1_Format);
      procedure Write_OCW1 is new x86.Port_IO.Outb (OCW1_Format);
   begin
      if irq in 0 .. 7 then
         port := MASTER_DATA;
      else
         IRQ_V := IRQ_V - 8;
         port := SLAVE_DATA;
      end if;

      OCW1 := Read_OCW1(Port);
      if OCW1 (IRQ_V) = CHANNEL_ENABLED then
         Logger.Log_Warning ("IRQ " & irq'Image & " already enabled");
      end if;

      OCW1 (IRQ_V) := CHANNEL_ENABLED;
      Write_OCW1 (Port, OCW1);
   end Clear_Mask;

   procedure Send_EOI (irq : IRQ_Number) is
      Slave_Index             : constant := 2;
   begin
      if irq >= 40 then
         Write_Slave_OCW2 ((EOI_Command => Non_Specific_EOI, others => <>));
      end if;
      Write_Master_OCW2 ((EOI_Command => Non_Specific_EOI, others => <>));

   end Send_EOI;

end pic;
