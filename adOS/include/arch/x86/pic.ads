------------------------------------------------------------------------------
--                                   PIC                                    --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    Programmable Interrupt Controller initialization.                     --
------------------------------------------------------------------------------

--  TODO: This unit needs to be revised to add PIC register records.
with System.Storage_Elements; use System.Storage_Elements;
with System;                  use System;
with x86.Port_IO;
with Interfaces;             use Interfaces;

package pic is
   pragma Preelaborate;
   procedure init;
   procedure Clear_Mask (irq : Integer);

private
   type PIT_PORT is (MASTER_CMD, MASTER_DATA, SLAVE_CMD, SLAVE_DATA);
   for PIT_PORT use
     (MASTER_CMD => 16#20#, MASTER_DATA => 16#21#, SLAVE_CMD => 16#A0#, SLAVE_DATA => 16#A1#);
end pic;
