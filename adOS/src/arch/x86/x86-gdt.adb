with Loggers;
with Util;
with System.Machine_Code;     use System.Machine_Code;


package body x86.gdt is
   use Standard.ASCII;
   package Logger renames Loggers;
   
   function Craft_Segment_Descriptor
     (base        : System.Address;
      limit       : Unsigned_32;
      access_byte : Unsigned_8;
      flags       : Unsigned_8) return Segment_Descriptor
   is
      base_integer : constant Unsigned_32 := Unsigned_32 (To_Integer (base) and 16#FFFFFFFF#);
   begin
      return
           (base_low    => Unsigned_16 (base_integer and 16#FFFF#),
            base_mid    => Unsigned_8 (Shift_Right (base_integer, 16) and 16#FF#),
            base_high   => Unsigned_8 (Shift_Right (base_integer, 24)),
            limit_low   => Unsigned_16 (limit and 16#FFFF#),
            flags       => Unsigned_4 (flags and 16#F#),
            access_byte => (access_byte),
            limit_high  => Unsigned_4 (Shift_Right (limit, 16) and 16#F#));
   end Craft_Segment_Descriptor;

   procedure flush_tss is
   begin
      ASM
        ("xor %%eax, %%eax" & LF & "mov $(5 * 8), %%ax" & LF & "ltr %%ax",
         Volatile => True,
         Clobber  => "eax");
   end flush_tss;


   procedure initialize_gdt is
      base_address : constant System.Address := To_Address (0);
      limit        : constant Unsigned_32 := 16#F_FFFF#;
   begin

      for Segment_Type in Global_Descriptor_Table'Range loop
         Global_Descriptor_Table (Segment_Type) := Get_Segment (Segment_Type);
      end loop;
      
      Init_TSS;

      gdt_pointer.limit := (Global_Descriptor_Table'Size - 1) / 8;
      gdt_pointer.base := Global_Descriptor_Table'Address;

      Logger.Log_Info ("gdt_pointer =" & gdt_pointer'Image);

      --  for i in Global_Descriptor_Table'Range loop
      --     -- !format off
      --     Logger.Log_Info
      --       ("GDT["
      --        & i'Image
      --        & "] = "
      --        & " Base: "
      --        & Global_Descriptor_Table (i).descriptor.base_low'Image
      --        & " Mid: "
      --        & Global_Descriptor_Table (i).descriptor.base_mid'Image
      --        & " High: "
      --        & Global_Descriptor_Table (i).descriptor.base_high'Image
      --        & " Limit: "
      --        & Global_Descriptor_Table (i).descriptor.limit_low'Image
      --        & " Flags: "
      --        & Global_Descriptor_Table (i).descriptor.flags'Image
      --        & " Access Byte: "
      --        & Global_Descriptor_Table (i).descriptor.access_byte'Image
      --        & " Limit High: "
      --        & Global_Descriptor_Table (i).descriptor.limit_high'Image);
      --     -- !format on
      --  end loop;
      load_gdt (gdt_pointer'Address);
      Logger.Log_Ok ("gdt loaded");
      flush_tss;
      Logger.Log_Ok ("tss flushed");
   end initialize_gdt;




   
end x86.gdt;