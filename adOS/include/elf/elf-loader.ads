with VFS;
with VFS.ISO;

generic
    with package File_System is new VFS.ISO (<>);
package ELF.Loader is
    pragma Preelaborate;

    function Prepare (File : in VFS.File_Descriptor) return ELF_Header;
    procedure Kernel_Load (File : in VFS.File_Descriptor; Header : in ELF_Header; CR3 : in out x86.vmm.CR3_register);
    function Read_Elf_Header is new File_System.read (ELF_Header);
    function Read_Elf_Program_Header is new File_System.read (ELF_Program_Header);


end Elf.Loader;