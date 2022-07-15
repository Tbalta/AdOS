with SERIAL;
with System.Storage_Elements; use System.Storage_Elements;
package body x86.idt is
   pragma Suppress (Index_Check);
   pragma Suppress (Overflow_Check);
   pragma Suppress (All_Checks);

   procedure add_entry
     (index : Natural; offset : Unsigned_32; selector : Unsigned_16;
      DPL   : Unsigned_8; type_attr : gate_type);
   procedure add_entry
     (index : Natural; offset : Unsigned_32; selector : Unsigned_16;
      DPL   : Unsigned_8; type_attr : gate_type)
   is
   begin
      interrupt_vector (index) :=
        (offset      => Unsigned_16 (offset), selector => selector,
         DPL         => DPL and 2#11#, present => True,
         offset_high => Unsigned_16 (Shift_Right (offset, 16)),
         entry_type  => type_attr, zero => 0);
   end add_entry;

   procedure init_idt is
      procedure load_idt (idt_ptr : Unsigned_32);
      pragma Import (C, load_idt, "load_idt");
      idt_ptr : idt_ptr_t;
   begin
      for i in error_vector_t'Range loop
         add_entry (i, error_vector (i), 8, 0, interrupt_32_bits);
      end loop;
      idt_ptr.base  := Unsigned_32 (To_Integer (error_vector'Address));
      idt_ptr.limit := Unsigned_16 (interrupt_vector'Size / 8 - 1);

      SERIAL.send_line
        ("idt size = " & idt_ptr.limit'Image & " idt base = " &
         idt_ptr.base'Image);
      load_idt (Unsigned_32 (To_Integer (idt_ptr'Address)));
   end init_idt;

   procedure handler
     (error_code : Unsigned_32; interrupt_code : Unsigned_32) is null;
end x86.idt;
