with Interfaces; use Interfaces;

with x86.Port_IO; use x86.Port_IO;

package body pic is

   procedure init is
      ICW4    : constant Unsigned_8 := 16#01#;
      SINGLE  : constant Unsigned_8 := 16#02#;
      EDGE    : constant Unsigned_8 := 16#04#;
      CASCADE : constant Unsigned_8 := 16#08#;
      INIT    : constant Unsigned_8 := 16#10#;

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
