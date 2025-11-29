------------------------------------------------------------------------------
--                                   PIC                                    --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

--  TODO: This unit needs to be revised to add PIC register records.
with Interfaces; use Interfaces;


package body pic is
   ---------
   -- Rep --
   ---------
   function Rep (P : PIT_PORT) return x86.Port_IO.Port_Address
   is (x86.Port_IO.Port_Address (PIT_PORT'Enum_Rep (P)));

   ----------
   -- Init --
   ----------
   procedure init is
      ICW4    : constant Unsigned_8 := 16#01#;
      SINGLE  : constant Unsigned_8 := 16#02#;
      EDGE    : constant Unsigned_8 := 16#04#;
      CASCADE : constant Unsigned_8 := 16#08#;
      INIT    : constant Unsigned_8 := 16#10#;

      pragma Unreferenced (SINGLE, EDGE, CASCADE);
      procedure Outb is new x86.Port_IO.Outb (Unsigned_8);
   begin
      Outb (Rep (MASTER_CMD), INIT or ICW4); -- ICW1
      Outb (Rep (SLAVE_CMD), INIT or ICW4); -- ICW1
      Outb (Rep (MASTER_DATA), 32); -- ICW2
      Outb (Rep (SLAVE_DATA), 40); -- ICW2

      Outb (Rep (MASTER_DATA), Shift_Left (1, 2)); -- ICW3
      Outb (Rep (SLAVE_DATA), 2); -- ICW3

      Outb (Rep (MASTER_DATA), 1); -- ICW4
      Outb (Rep (SLAVE_DATA), 1); -- ICW4

      Outb (Rep (MASTER_DATA), 16#FF# and not (Shift_Left (1, 2))); -- ICW4
      Outb (Rep (SLAVE_DATA), 16#FF#); -- ICW4
   end init;
end pic;
