with SERIAL;
with System.Storage_Elements; use System.Storage_Elements;
with System.Machine_Code; use System.Machine_Code;
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

   function Convert (Input : idt_entry) return Record_Bytes is
      Result : constant Record_Bytes;
      for Result'Address use Input'Address;
      pragma Import (Convention => Ada, Entity => Result);
   begin
      return Result;
   end Convert;

   procedure init_idt is
      procedure load_idt (idt_ptr : Unsigned_32);
      procedure timer_callback;
      pragma Import (C, load_idt, "load_idt");
      pragma Import (C, timer_callback, "isr_stub_32");
      idt_ptr : idt_ptr_t;
   begin
      for i in error_vector_t'Range loop
         add_entry (i, error_vector (i), 8, 0, trap_gate_32_bits);
         SERIAL.send_line (error_vector (i)'Image);
      end loop;
      add_entry
        (32, Unsigned_32 (To_Integer (timer_callback'Address)), 8, 0,
         interrupt_32_bits);
      idt_ptr.base  := Unsigned_32 (To_Integer (interrupt_vector'Address));
      idt_ptr.limit := Unsigned_16 (interrupt_vector'Size / 8 - 1);

      SERIAL.send_line
        ("idt size = " & idt_ptr.limit'Image & " idt base = " &
         idt_ptr.base'Image);
      load_idt (Unsigned_32 (To_Integer (idt_ptr'Address)));
      declare
         test : constant Record_Bytes := Convert (interrupt_vector (0));
      begin
         for i in test'Range loop
            SERIAL.send_hex (Unsigned_32 (test (i)));
            SERIAL.send_string (" ");
         end loop;
      end;
   end init_idt;

   procedure handler
     (interrupt_code : Unsigned_32; error_code : Unsigned_32;
      eip            : Unsigned_32; cs : Unsigned_32)
   is
   begin
      SERIAL.send_line
        ("error_code = " & error_code'Image & " interrupt_code = " &
         interrupt_code'Image & " eip = " & eip'Image & " cs = " & cs'Image);

      while True loop
         ASM ("hlt", Volatile => True);
      end loop;

   end handler;
end x86.idt;
