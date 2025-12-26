------------------------------------------------------------------------------
--                                   PIC                                    --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    Programmable Interrupt Controller initialization.                     --
------------------------------------------------------------------------------

--  TODO: This unit needs to be revised to add PIC register records.
with System.Storage_Elements; use System.Storage_Elements;
with System;                  use System;
with x86.Port_IO;
with Interfaces;              use Interfaces;

package pic is
   pragma Preelaborate;
   procedure init;
   type IRQ_Line is new Natural range 0 .. 15;
   type IRQ_Number is new Natural range 32 .. 47;
   procedure Clear_Mask (irq : IRQ_Line);
   procedure Send_EOI (irq : IRQ_Number);


private
   ---------------   
   -- PIC Ports --
   ---------------   
   use all type x86.Port_IO.Port_Address;
   pragma Warnings (Off, "membership test on ""PIT_PORT"" uses predefined equality");
   subtype PIT_PORT is x86.Port_IO.Port_Address
      with Static_Predicate => PIT_PORT in  16#20# |  16#21# | 16#A0# | 16#A1#;
   pragma Warnings (On, "membership test on ""PIT_PORT"" uses predefined equality");


   MASTER_CMD  : constant PIT_PORT := 16#20#;
   MASTER_DATA : constant PIT_PORT := 16#21#;
   SLAVE_CMD   : constant PIT_PORT := 16#A0#;
   SLAVE_DATA  : constant PIT_PORT := 16#A1#;

   -----------
   -- ICW 1 --
   -----------
   type Call_Interval_Address is (
      Interval_Of_8,
      Interval_Of_4
   );
   for Call_Interval_Address use (
      Interval_Of_8 => 0,
      Interval_Of_4 => 1
   );

   type Trigger_Mode_Kind is (
      Edge_Triggered,
      Level_Triggered
   );
   for Trigger_Mode_Kind use (
      Edge_Triggered  => 0,
      Level_Triggered => 1
   );

   type ICW1_8086_Format is record
      IC4_Needed   : Boolean;
      Single_Mode  : Boolean;
      ADI          : Call_Interval_Address := Interval_Of_8;
      Trigger_Mode : Trigger_Mode_Kind;
      One          : Unsigned_1 := 1;
   end record
      with Size => 8;
   for ICW1_8086_Format use record
      IC4_Needed   at 0 range 0 .. 0;
      Single_Mode  at 0 range 1 .. 1;
      ADI          at 0 range 2 .. 2; 
      Trigger_Mode at 0 range 3 .. 3;
      One          at 0 range 4 .. 4;
   end record;
   procedure Write_Master_ICW1 is new x86.Port_IO.Write_Port_8 (MASTER_CMD, ICW1_8086_Format);
   procedure Write_Slave_ICW1 is new x86.Port_IO.Write_Port_8 (SLAVE_CMD, ICW1_8086_Format);

   -----------
   -- ICW 2 --
   -----------
   type ICW2_8086_Format is record
      Interrupt_Address_T7_T3 : Unsigned_5;
   end record
      with Size => 8;
   for ICW2_8086_Format use record
      Interrupt_Address_T7_T3 at 0 range 3 .. 7;
   end record;
   procedure Write_Master_ICW2 is new x86.Port_IO.Write_Port_8 (MASTER_DATA, ICW2_8086_Format);
   procedure Write_Slave_ICW2 is new x86.Port_IO.Write_Port_8 (SLAVE_DATA, ICW2_8086_Format);

   -----------
   -- ICW 3 --
   -----------
   type Interrupt_Slave_Index is range 0 .. 7;
   type ICW3_Master_Format is array (Natural range 0 .. 7) of Boolean
      with Size => 8,
           Component_Size => 1;
   procedure Write_Master_ICW3 is new x86.Port_IO.Write_Port_8 (MASTER_DATA, ICW3_Master_Format);

   type ICW3_Slave_Format is record
      Slave_Index : Unsigned_3;
   end record
      with Size => 8;
   for ICW3_Slave_Format use record
      Slave_Index at 0 range 0 .. 2;
   end record;
   procedure Write_Slave_ICW3 is new x86.Port_IO.Write_Port_8 (SLAVE_DATA, ICW3_Slave_Format);


   -----------
   -- ICW 4 --
   -----------
   type Buffer_Mode_Kind is (
      Non_Buffered,
      Buffered_Mode_Slave,
      Buffered_Mode_Master
   );
   for Buffer_Mode_Kind use (
      Non_Buffered => 2#00#,
      Buffered_Mode_Slave => 2#10#,
      Buffered_Mode_Master => 2#11#
   );

   type ICW4_Format is record
      Is_8086                  : Boolean;
      Auto_EOI_Enable          : Boolean;
      Buffer_Mode              : Buffer_Mode_Kind;
      Fully_Nested_Mode_Enable : Boolean;
   end record
      with Size => 8;
   for ICW4_Format use record
      Is_8086                  at 0 range 0 .. 0;
      Auto_EOI_Enable          at 0 range 1 .. 1;
      Buffer_Mode              at 0 range 2 .. 3;
      Fully_Nested_Mode_Enable at 0 range 4 .. 4;
   end record;
   procedure Write_Master_ICW4 is new x86.Port_IO.Write_Port_8 (MASTER_DATA, ICW4_Format);
   procedure Write_Slave_ICW4 is new x86.Port_IO.Write_Port_8 (SLAVE_DATA, ICW4_Format);

   -----------
   -- OCW 1 --
   -----------
   type Interrupt_Mask_Kind is (CHANNEL_ENABLED, CHANNEL_MASKED);
   for Interrupt_Mask_Kind use (CHANNEL_ENABLED => 0, CHANNEL_MASKED => 1);
   for Interrupt_Mask_Kind'Size use 1;

   type OCW1_Format is array (IRQ_Line range 0 .. 7) of Interrupt_Mask_Kind
      with Size => 8,
           Component_Size => 1;
   procedure Write_Master_OCW1 is new x86.Port_IO.Write_Port_8 (MASTER_DATA, OCW1_Format);
   procedure Write_Slave_OCW1 is new x86.Port_IO.Write_Port_8 (SLAVE_DATA, OCW1_Format);

   -----------
   -- OCW 2 --
   -----------
   type EOI_Command_Kind is (
      Rotate_In_Automatic_Mode_Clear,
      Non_Specific_EOI,
      No_Operation,
      Specific_EOI,
      Rotate_In_Automatic_Mode_Set,
      Rotate_On_Non_Specific_EOI,
      Set_Priority_Command,
      Rotate_On_Specific_EOI
   );
   for EOI_Command_Kind use (
      Rotate_In_Automatic_Mode_Clear => 2#000#,
      Non_Specific_EOI => 2#001#,
      No_Operation => 2#010#,
      Specific_EOI => 2#011#,
      Rotate_In_Automatic_Mode_Set => 2#100#,
      Rotate_On_Non_Specific_EOI => 2#101#,
      Set_Priority_Command => 2#110#,
      Rotate_On_Specific_EOI => 2#111#
   );
   type OCW2_Format is record
      Interrupt_Level : Unsigned_3;
      OCW2_Select : Unsigned_2 := 0;
      EOI_Command : EOI_Command_Kind;
   end record
      with Size => 8,
           Dynamic_Predicate => OCW2_Format.OCW2_Select = 2#00#;
   for OCW2_Format use record
      Interrupt_Level at 0 range 0 .. 2;
      OCW2_Select     at 0 range 3 .. 4;
      EOI_Command     at 0 range 5 .. 7;
   end record;
   procedure Write_Master_OCW2 is new x86.Port_IO.Write_Port_8 (MASTER_CMD, OCW2_Format);
   procedure Write_Slave_OCW2 is new x86.Port_IO.Write_Port_8 (SLAVE_CMD, OCW2_Format);

   
end pic;
