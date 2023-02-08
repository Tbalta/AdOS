with System.Storage_Elements; use System.Storage_Elements;
with System;                  use System;

package pic is
   pragma Preelaborate;
   procedure init;
   type PIT_PORT is (MASTER_CMD, MASTER_DATA, SLAVE_CMD, SLAVE_DATA);
   for PIT_PORT use
     (MASTER_CMD  => 16#20#,
      MASTER_DATA => 16#21#,
      SLAVE_CMD   => 16#A0#,
      SLAVE_DATA  => 16#A1#);
   function Rep
     (P : PIT_PORT) return System.Address is
     (To_Address (PIT_PORT'Enum_Rep (P)));

end pic;
