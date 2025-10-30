with x86.vmm;
with x86.pmm;
with Ada.Unchecked_Conversion;
with Interfaces; use Interfaces;

package ELF is
   pragma Preelaborate;
   ------------------------
   -- ELF Data Structure --
   ------------------------

   --  ELF Header  --
   type ELF_Identifier is record
      EI_MAG        : String (1 .. 4);
      EI_CLASS      : Unsigned_8;
      EI_DATA       : Unsigned_8;
      EI_VERSION    : Unsigned_8;
      EI_OSABI      : Unsigned_8;
      EI_ABIVERSION : Unsigned_8;
      EI_PAD        : String (1 .. 7);
   end record
   with Pack => True, Size => 128;

   for ELF_Identifier use
     record
       EI_MAG at 0 range 0 .. 31;
       EI_CLASS at 4 range 0 .. 7;
       EI_DATA at 5 range 0 .. 7;
       EI_VERSION at 6 range 0 .. 7;
       EI_OSABI at 7 range 0 .. 7;
       EI_ABIVERSION at 8 range 0 .. 7;
       EI_PAD at 9 range 0 .. 55;
     end record;

   type Object_File_Type is (NONE, REL, EXEC, DYN, CORE, LOOS, HIOS, LOPROC, HIPROC);
   for Object_File_Type use
     (NONE   => 0,
      REL    => 1,
      EXEC   => 2,
      DYN    => 3,
      CORE   => 4,
      LOOS   => 16#FE00#,
      HIOS   => 16#FEFF#,
      LOPROC => 16#FF00#,
      HIPROC => 16#FFFF#);

   type ELF_Header is record
      e_ident     : ELF_Identifier;
      e_type      : Object_File_Type;
      e_machine   : Unsigned_16;
      e_version   : Unsigned_32;
      e_entry     : x86.Virtual_Address;
      e_phoff     : Unsigned_32;
      e_shoff     : Unsigned_32;
      e_flags     : Unsigned_32;
      e_ehsize    : Unsigned_16;
      e_phentsize : Unsigned_16;
      e_phnum     : Unsigned_16;
      e_shentsize : Unsigned_16;
      e_shnum     : Unsigned_16;
      e_shstrndx  : Unsigned_16;
   end record
   with Pack => True, Size => 52 * 8;

   for ELF_Header use
     record
       e_ident at 0 range 0 .. 127;
       e_type at 16 range 0 .. 15;
       e_machine at 18 range 0 .. 15;
       e_version at 20 range 0 .. 31;
       e_entry at 24 range 0 .. 31;
       e_phoff at 28 range 0 .. 31;
       e_shoff at 32 range 0 .. 31;
       e_flags at 36 range 0 .. 31;
       e_ehsize at 40 range 0 .. 15;
       e_phentsize at 42 range 0 .. 15;
       e_phnum at 44 range 0 .. 15;
       e_shentsize at 46 range 0 .. 15;
       e_shnum at 48 range 0 .. 15;
       e_shstrndx at 50 range 0 .. 15;
     end record;
   ------------------------

   -- ELF Program Header --
   type Segment_Type is
     (PT_NULL, PT_LOAD, PT_DYNAMIC, PT_INTERP, PT_NOTE, PT_SHLIB, PT_PHDR, PT_LOPROC, PT_HIPROC);
   for Segment_Type use
     (PT_NULL    => 0,
      PT_LOAD    => 1,
      PT_DYNAMIC => 2,
      PT_INTERP  => 3,
      PT_NOTE    => 4,
      PT_SHLIB   => 5,
      PT_PHDR    => 6,
      PT_LOPROC  => 16#70000000#,
      PT_HIPROC  => 16#7FFFFFFF#);

   type Segment_Flags is (PF_X, PF_W, PF_R);
   for Segment_Flags use (PF_X => 1, PF_W => 2, PF_R => 4);

   function Segment_Type_To_Integer is new Ada.Unchecked_Conversion (Segment_Type, Unsigned_32);

   type ELF_Program_Header is record
      p_type   : Segment_Type;
      p_offset : Unsigned_32;
      p_vaddr  : x86.Virtual_Address;
      p_paddr  : x86.Physical_Address;
      p_filesz : Unsigned_32;
      p_memsz  : Unsigned_32;
      p_flags  : Segment_Flags;
      p_align  : Unsigned_32;
   end record
   with Pack => True, Size => 32 * 8;

   for ELF_Program_Header use
     record
       p_type at 0 range 0 .. 31;
       p_offset at 4 range 0 .. 31;
       p_vaddr at 8 range 0 .. 31;
       p_paddr at 12 range 0 .. 31;
       p_filesz at 16 range 0 .. 31;
       p_memsz at 20 range 0 .. 31;
       p_flags at 24 range 0 .. 31;
       p_align at 28 range 0 .. 31;
     end record;
end ELF;
