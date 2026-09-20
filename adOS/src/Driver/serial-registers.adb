------------------------------------------------------------------------------
--                             SERIAL.REGISTERS                             --
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

package body SERIAL.Registers is


   function Read_Receive_Buffer (COM : x86.Port_IO.Port_Address) return Receive_Buffer_Register
   is
      function Read_RBR is new x86.Port_IO.Read_Port_8 (Get_Receive_Buffer_Port (COM), Receive_Buffer_Register);
   begin
      return Read_RBR;
   end Read_Receive_Buffer;

   ------------------------------
   -- Transmit Buffer Register --
   ------------------------------
   procedure Write_Transmit_Buffer (COM : x86.Port_IO.Port_Address; Value : Transmit_Buffer_Register)
   is
      procedure Write_TBR is new x86.Port_IO.Write_Port_8 (Get_Transmit_Buffer_Port (COM), Transmit_Buffer_Register);
   begin
      Write_TBR (Value);
   end Write_Transmit_Buffer;

end SERIAL.Registers;
