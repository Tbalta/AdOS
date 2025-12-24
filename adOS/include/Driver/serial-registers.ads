------------------------------------------------------------------------------
--                             SERIAL.REGISTERS                             --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with x86.Port_IO;
package SERIAL.REGISTERS is
   pragma Preelaborate;
   ----------------------
   -- Serial Registers --
   ----------------------
   subtype Register_Kind is x86.Port_IO.Port_Address range 0 .. 7;
   RECEIVE_BUFFER_OFFSET           : constant Register_Kind := 0;
   TRANSMIT_BUFFER_OFFSET          : constant Register_Kind := 0;
   INTERUPT_ENABLE_REGISTER_OFFSET : constant Register_Kind := 1;
   DIVISOR_LOW_REGISTER_OFFSET     : constant Register_Kind := 0;
   DIVISOR_HIGH_REGISTER_OFFSET    : constant Register_Kind := 1;
   INTERRUPT_IDENT_REGISTER_OFFSET : constant Register_Kind := 2;
   FIFO_CONTROL_REGISTER_OFFSET    : constant Register_Kind := 2;
   LINE_CONTROL_REGISTER_OFFSET    : constant Register_Kind := 3;
   MODEM_CONTROL_REGISTER_OFFSET   : constant Register_Kind := 4;
   LINE_STATUS_REGISTER_OFFSET     : constant Register_Kind := 5;
   MODEM_STATUS_REGISTER_OFFSET    : constant Register_Kind := 6;
   SCRATCH_REGISTER_OFFSET         : constant Register_Kind := 7;
   use all type x86.Port_IO.Port_Address;


   -----------------------------
   -- Receive Buffer Register --
   -----------------------------
   generic
      type Receive_Buffer_Register is private;
   function Read_Receive_Buffer (COM : x86.Port_IO.Port_Address) return Receive_Buffer_Register;
   function Get_Receive_Buffer_Port (COM : x86.Port_IO.Port_Address) return x86.Port_IO.Port_Address is (COM + RECEIVE_BUFFER_OFFSET);


   ------------------------------
   -- Transmit Buffer Register --
   ------------------------------
   generic
      type Transmit_Buffer_Register is private;
   procedure Write_Transmit_Buffer (COM : x86.Port_IO.Port_Address; Value : Transmit_Buffer_Register);
   function Get_Transmit_Buffer_Port (COM : x86.Port_IO.Port_Address) return x86.Port_IO.Port_Address is (COM + TRANSMIT_BUFFER_OFFSET);


   -------------------------------
   -- Divisor Low/High Register --
   -------------------------------
   procedure Write_Divisor_Low (COM : x86.Port_IO.Port_Address; Value : Unsigned_8);
   function Get_Divisor_Low_Port (COM : x86.Port_IO.Port_Address) return x86.Port_IO.Port_Address is (COM + DIVISOR_LOW_REGISTER_OFFSET);

   procedure Write_Divisor_High (COM : x86.Port_IO.Port_Address; Value : Unsigned_8);
   function Get_Divisor_High_Port (COM : x86.Port_IO.Port_Address) return x86.Port_IO.Port_Address is (COM + DIVISOR_HIGH_REGISTER_OFFSET);

   ---------------------------
   -- Line_Control_Register --
   ---------------------------
   type Character_Length is
     (Five_Bits,
      Six_Bits,
      Seven_Bits,
      Eight_Bits);
   for Character_Length use
       (Five_Bits => 2#00#,
         Six_Bits  => 2#01#,
         Seven_Bits => 2#10#,
         Eight_Bits => 2#11#);
   for Character_Length'Size use 2;

   type Parity_Kind is
     (NONE,
      ODD,
      EVEN,
      MARK,
      SPACE);
   for Parity_Kind use 
       (NONE => 2#000#,
         ODD  => 2#001#,
         EVEN => 2#011#,
         MARK => 2#101#,
         SPACE=> 2#111#);
   for Parity_Kind'Size use 3;

   type Line_Control_Register is record
      Data         : Character_Length;
      Stop         : Boolean;
      Parity       : Parity_Kind;
      Break_Enable : Boolean;
      DLAB         : Boolean;
   end record;
   for Line_Control_Register use record
      Data         at 0 range 0 .. 1;
      Stop         at 0 range 2 .. 2;
      Parity       at 0 range 3 .. 5;
      Break_Enable at 0 range 6 .. 6;
      DLAB         at 0 range 7 .. 7;
   end record;
   for Line_Control_Register'Size use 8;
   for Line_Control_Register'Object_Size use 8;

   function Get_Line_Control_Register_Port (COM : x86.Port_IO.Port_Address) return x86.Port_IO.Port_Address is (COM + LINE_CONTROL_REGISTER_OFFSET);
   procedure Write_Line_Control_Register (COM : x86.Port_IO.Port_Address; LCR : Line_Control_Register);
   function Read_Line_Control_Register (COM : x86.Port_IO.Port_Address) return Line_Control_Register;


   ---------------------------
   -- FIFO_Control_Register --
   ---------------------------
   type Interrupt_Trigger_Level is
     (Level_1_Byte,
      Level_4_Bytes,
      Level_8_Bytes,
      Level_14_Bytes);
   for Interrupt_Trigger_Level use
         (Level_1_Byte  => 2#00#,
            Level_4_Bytes => 2#01#,
            Level_8_Bytes => 2#10#,
            Level_14_Bytes=> 2#11#);
   for Interrupt_Trigger_Level'Size use 2;

   type FIFO_Control_Register is record
      Enable_FIFO      : Boolean;
      Clear_Receive    : Boolean;
      Clear_Transmit   : Boolean;
      DMA_Mode         : Boolean;
      Reserved         : Unsigned_2;
      Trigger_Level    : Interrupt_Trigger_Level;
   end record;
   for FIFO_Control_Register use record
      Enable_FIFO      at 0 range 0 .. 0;
      Clear_Receive    at 0 range 1 .. 1;
      Clear_Transmit   at 0 range 2 .. 2;
      DMA_Mode         at 0 range 3 .. 3;
      Reserved         at 0 range 4 .. 5;
      Trigger_Level    at 0 range 6 .. 7;
   end record;
   for FIFO_Control_Register'Size use 8;
   for FIFO_Control_Register'Object_Size use 8;

   function Get_FIFO_Control_Register_Port (COM : x86.Port_IO.Port_Address) return x86.Port_IO.Port_Address is (COM + FIFO_CONTROL_REGISTER_OFFSET);
   procedure Write_FIFO_Control_Register (COM : x86.Port_IO.Port_Address; FCR : FIFO_Control_Register);

   ---------------------------
   -- Line_Status_Register --
   ---------------------------
   type Line_Status_Register is record
      Data_Ready : Boolean;
      Overrun_Error : Boolean;
      Parity_Error : Boolean;
      Framing_Error : Boolean;
      Break_Indicator : Boolean;
      Transmitter_Holding_Register_Empty : Boolean;
      Transmitter_Empty : Boolean;
      Impending_Error : Boolean;
   end record;
   for Line_Status_Register use record
      Data_Ready at 0 range 0 .. 0;
      Overrun_Error at 0 range 1 .. 1;
      Parity_Error at 0 range 2 .. 2;
      Framing_Error at 0 range 3 .. 3;
      Break_Indicator at 0 range 4 .. 4;
      Transmitter_Holding_Register_Empty at 0 range 5 .. 5;
      Transmitter_Empty at 0 range 6 .. 6;
      Impending_Error at 0 range 7 .. 7;
   end record;
   for Line_Status_Register'Size use 8;
   for Line_Status_Register'Object_Size use 8;

   function Get_Line_Status_Register_Port (COM : x86.Port_IO.Port_Address) return x86.Port_IO.Port_Address is (COM + LINE_STATUS_REGISTER_OFFSET);
   function Read_Line_Status_Register (COM : x86.Port_IO.Port_Address) return Line_Status_Register;
private

end SERIAL.REGISTERS;