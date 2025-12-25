------------------------------------------------------------------------------
--                                  SERIAL                                  --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with x86.Port_IO;
with System.Storage_Elements; use System.Storage_Elements;
with System;
with System.Address_To_Access_Conversions;
with SERIAL.REGISTERS; use SERIAL.REGISTERS;

package body SERIAL is

   ---------------------
   -- DLAB Management --
   ---------------------
   procedure Enable_DLAB (COM : x86.Port_IO.Port_Address) is
      LCR : Line_Control_Register := Read_Line_Control_Register (COM);
   begin
      LCR.DLAB := True;
      Write_Line_Control_Register (COM, LCR);
      DLAB_Enabled := True;
   end Enable_DLAB;

   procedure Disable_DLAB (COM : x86.Port_IO.Port_Address) is
      LCR : Line_Control_Register := Read_Line_Control_Register (COM);
   begin
      LCR.DLAB := False;
      Write_Line_Control_Register (COM, LCR);
      DLAB_Enabled := False;
   end Disable_DLAB;

   --------------------------
   -- Set Baudrate Divisor --
   --------------------------
   procedure Set_Divisor (COM : x86.Port_IO.Port_Address; Divisor : Baudrate_Divisor) is
      divisor_low  : Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Divisor and 16#FF#);
      divisor_high : Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Shift_Right (Divisor, 8) and 16#FF#);
   begin
      pragma Assert (DLAB_Enabled, "DLAB must be enabled to set baud rate divisor");
      Write_Divisor_Low (COM, divisor_low);
      Write_Divisor_High (COM, divisor_high);
   end Set_Divisor;

   ------------------------
   -- Set Line Control --
   ------------------------
   procedure Set_Line_Control (COM : x86.Port_IO.Port_Address; Data_Length : Character_Length; Stop : Boolean; Parity : Parity_Kind; Break_Enable : Boolean) is
      LCR : Line_Control_Register := (Data        => Data_Length,
                                     Stop         => Stop,
                                     Parity       => Parity,
                                     Break_Enable => Break_Enable,
                                     DLAB         => DLAB_Enabled);
   begin
      Write_Line_Control_Register (COM, LCR);
   end Set_Line_Control;

   procedure outb is new x86.Port_IO.Outb (Unsigned_8);
   function inb is new x86.Port_IO.Inb (Unsigned_8);

   procedure Write_COM1_Transmit_Buffer is new
     x86.Port_IO.Write_Port_8 (COM1, Interfaces.Unsigned_8);

   procedure Set_Baud_Rate (port : COM_Port; divisor : Baudrate_Divisor) is
   begin
      Write_Interrupt_Enable_Register (port, (others => False));
      Disable_DLAB (port);
      Set_Line_Control (port, Eight_Bits, True, NONE, False);
      Enable_DLAB (port);
      Set_Divisor (port, divisor);
      Write_FIFO_Control_Register (port, (Enable_FIFO    => True,
                                          Clear_Receive  => True,
                                          Clear_Transmit => True,
                                          DMA_Mode       => False,
                                          Reserved       => 0,
                                          Trigger_Level  => Level_14_Bytes));
      Disable_DLAB (port);
   end Set_Baud_Rate;


   -------------------
   -- Can Send Byte --
   -------------------
   function can_send_byte (port : COM_Port) return Boolean is
   begin
      return Read_Line_Status_Register (port).Transmitter_Holding_Register_Empty;
   end can_send_byte;


   ---------------
   -- Send Char --
   ---------------
   procedure send_char is new Write_Transmit_Buffer (Character);
   procedure send_cchar (port : COM_Port; c : Interfaces.C.char) is
   begin
      send_char (port, To_Ada (c));
   end send_cchar;

   procedure send_string (port : COM_Port; data : String) is
   begin
      for character in data'Range loop
         send_char (port, data (character));
      end loop;
   end send_string;

   procedure send_hex (port : COM_Port; data : Interfaces.Unsigned_32) is
      hex_array : constant String := "0123456789ABCDEF";
      procedure recur (number : Interfaces.Unsigned_32);
      procedure recur (number : Interfaces.Unsigned_32) is
      begin
         if number = 0 then
            return;
         end if;
         recur (number / 16);
         send_char (port, hex_array (Integer (number mod 16) + 1));
      end recur;
   begin
      send_string (port, "0x");
      if data = 0 then
         send_char (port, '0');
      end if;
      recur (data);
      send_string (port, " ");
   end send_hex;

   procedure Init_COM (port : COM_Port; rate : Baudrate) is
   begin
      while not can_send_byte (port) loop
         null;
      end loop;
      Set_Baud_Rate (port, Baudrate_Divisor (rate / Baudrate'Last));
   end Init_COM;

   procedure send_raw_byte is new Write_Transmit_Buffer (Interfaces.Unsigned_8);

   procedure send_line (port : COM_Port; data : String) is
   begin
      send_string (port, data);
      send_char (port, Character'Val (10));
   end send_line;

   procedure send_raw_buffer (port : COM_Port; buffer : System.Address; size : Storage_Count) is
      type Byte_Array is array (Storage_Offset range 1 .. size) of Interfaces.Unsigned_8;
      package Conversion is new System.Address_To_Access_Conversions (Byte_Array);
      byte_array_access : access Byte_Array := Conversion.To_Pointer (buffer);

   begin
      for Byte of byte_array_access.all loop
         send_raw_byte (port, Byte);
      end loop;
   end send_raw_buffer;

end SERIAL;
