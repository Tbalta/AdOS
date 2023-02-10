with Interfaces;
with System;
-------------------------------------------------------------------------------
--  X86.PORT_IO
--
--  Purpose:
--    This package contains functionality for port-mapped I/O on the x86
--    platform.
--    Functions are included for inputting and outputting data to port-mapped
--    addresses, useful for interacting with system peripherals.
-------------------------------------------------------------------------------
package x86.Port_IO is
   pragma Preelaborate (x86.Port_IO);
   ----------------------------------------------------------------------------
   --  Inb
   --
   --  Purpose:
   --    This function reads a byte from a particular IO port.
   --  Exceptions:
   --    None.
   ----------------------------------------------------------------------------
   function Inb (Port : System.Address) return Interfaces.Unsigned_8 with
      Volatile_Function;

   ----------------------------------------------------------------------------
      --  Outb
      --
      --  Purpose:
      --    This function writes a byte to a particular IO port.
      --  Exceptions:
      --    None.
   ----------------------------------------------------------------------------
   procedure Outb (Port : System.Address; Data : Interfaces.Unsigned_8);


   ----------------------------------------------------------------------------
   --  Inw
   --
   --  Purpose:
   --    This function reads a word from a particular IO port.
   --  Exceptions:
   --    None.
   ----------------------------------------------------------------------------
   function Inw (Port : System.Address) return Interfaces.Unsigned_16 with
      Volatile_Function;
   
   ----------------------------------------------------------------------------
   --  Outw
   --
   --  Purpose:
   --    This function writes a word to a particular IO port.
   --  Exceptions:
   --    None.
   ----------------------------------------------------------------------------
   procedure Outw (Port : System.Address; Data : Interfaces.Unsigned_16);
end x86.Port_IO;
