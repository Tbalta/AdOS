------------------------------------------------------------------------------
--                             SERIAL.GENERICS                              --
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

package body SERIAL.Generics is

   -----------------------------
   -- Receive Buffer Register --
   -----------------------------
   function Read_Serial_Register (COM : x86.Port_IO.Port_Address) return Serial_Register
   is
      use all type x86.Port_IO.Port_Address;
      function Port_Read is new x86.Port_IO.Read_Port_8 (COM + Register_Port, Serial_Register);
   begin
      return Port_Read;
   end Read_Serial_Register;

   procedure Write_Serial_Register (COM : x86.Port_IO.Port_Address; Value : Serial_Register)
   is
      use all type x86.Port_Io.Port_Address;
      procedure Port_Write is new x86.Port_IO.Write_Port_8 (COM + Register_Port, Serial_Register);
   begin
      Port_Write (Value);
   end Write_Serial_Register;

end SERIAL.Generics;
