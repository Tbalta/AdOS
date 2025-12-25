------------------------------------------------------------------------------
--                                ELF.LOADER                                --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with File_System;

package ELF.Loader is
   pragma Preelaborate;

   function Get_Elf_Header (File : in File_System.File_Descriptor) return ELF_Header;
   procedure Load_Elf
     (File   : in File_System.File_Descriptor;
      Header : in ELF_Header;
      CR3    : in out x86.vmm.CR3_register);
   function Read_Elf_Header is new File_System.read (ELF_Header);
   function Read_Elf_Program_Header is new File_System.read (ELF_Program_Header);


end Elf.Loader;
