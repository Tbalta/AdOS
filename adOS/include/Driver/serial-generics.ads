------------------------------------------------------------------------------
--                             SERIAL.GENERICS                              --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with x86.Port_IO;

package SERIAL.Generics is
   pragma Preelaborate;

   generic
      Register_Port : x86.Port_IO.Port_Address;
      type Serial_Register is private;
   function Read_Serial_Register (COM : x86.Port_IO.Port_Address) return Serial_Register;

   generic
      Register_Port : x86.Port_IO.Port_Address;
      type Serial_Register is private;
   procedure Write_Serial_Register (COM : x86.Port_IO.Port_Address; Value : Serial_Register);      


end SERIAL.Generics;