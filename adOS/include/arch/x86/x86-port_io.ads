------------------------------------------------------------------------------
--                               X86.PORT_IO                                --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    port-mapped I/O communication for x86.                                --
------------------------------------------------------------------------------
with System;

package x86.Port_IO is
   pragma Pure;

   type Port_Address is new System.Address;
   ----------------------------------------------------------------------------
   --  Inb
   --
   --  Purpose:
   --    This function reads a byte from a designated IO port.
   --  Exceptions:
   --    Assert_Error when Read_Type'Size /= 8
   ----------------------------------------------------------------------------
   generic
      type Read_Type is private;
   function Inb (Port : Port_Address) return Read_Type with Volatile_Function;

   ----------------------------------------------------------------------------
   --  Read_Port_8
   --
   --  Purpose:
   --    Reads a byte of from a designated IO port.
   --  Exceptions:
   --    Assert_Error when Read_Type'Size /= 8
   ----------------------------------------------------------------------------
   generic
      Port : Port_Address;
      type Read_Type is private;
   function Read_Port_8 return Read_Type with Volatile_Function;

   ----------------------------------------------------------------------------
   --  8 bit write functions
   --
   --  Purpose:
   --    Writes Write_Type to a designated IO port.
   --  Exceptions:
   --    Assert_Error when Write_Type'Size /= 8
   ----------------------------------------------------------------------------
   generic
      type Write_Type is private;
   procedure Outb (Port : Port_Address; Data : Write_Type);

   generic
      Port : Port_Address;
      type Write_Type is private;
   procedure Write_Port_8 (Data : Write_Type);


   ----------------------------------------------------------------------------
   --  16 bit read
   --
   --  Purpose:
   --    This function reads a word from a designated IO port.
   --  Exceptions:
   --    Assert_Error when Read_Type'Size /= 16
   ----------------------------------------------------------------------------
   generic
      type Read_Type is private;
   function Inw (Port : Port_Address) return Read_Type with Volatile_Function;

   ----------------------------------------------------------------------------
   --  16 bit write functions
   --
   --  Purpose:
   --    This function writes a word to a designated IO port.
   --  Exceptions:
   --    Assert_Error when Write_Type'Size /= 16
   ----------------------------------------------------------------------------
   generic
      type Write_Type is private;
   procedure Outw (Port : Port_Address; Data : Write_Type);
end x86.Port_IO;
