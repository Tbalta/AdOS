------------------------------------------------------------------------------
--                                  SERIAL                                  --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with Interfaces;              use Interfaces;
with Interfaces.C;            use Interfaces.C;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with x86.Port_IO;

package SERIAL is
   pragma Preelaborate;

   ---------------
   -- COM Ports --
   ---------------
   subtype COM_Port is x86.Port_IO.Port_Address;
   COM1 : constant COM_Port := 16#3F8#;
   COM2 : constant COM_Port := 16#2F8#;
   COM3 : constant COM_Port := 16#3E8#;
   COM4 : constant COM_Port := 16#2E8#;
   COM5 : constant COM_Port := 16#5F8#;
   COM6 : constant COM_Port := 16#4F8#;
   COM8 : constant COM_Port := 16#4E8#;
   COM7 : constant COM_Port := 16#5E8#;

   --------------
   -- Baudrate --
   --------------
   subtype Baudrate is Natural range 1 .. 115_200;
   procedure Init_COM (port : COM_Port; rate : Baudrate);

   -------------
   -- Senders --
   -------------
   procedure send_cchar (port : COM_Port; c : Interfaces.C.char)
      with Export, Convention => C, External_Name => "send_cchar";
   procedure send_string (port : COM_Port; data : String);
   procedure send_hex (port : COM_Port; data : Interfaces.Unsigned_32);
   procedure send_line (port : COM_Port; data : in String)
      with Export, Convention => Ada, External_Name => "__gnat_debug_log";
   procedure send_raw_buffer (port : COM_Port; buffer : System.Address; size : Storage_Count);


private
   subtype Baudrate_Divisor is Unsigned_16;
   procedure Set_Baud_Rate (port : COM_Port; serial_divisor : Baudrate_Divisor);
   function can_send_byte (port : COM_Port) return Boolean;

   DLAB_Enabled : Boolean := False;

end SERIAL;
