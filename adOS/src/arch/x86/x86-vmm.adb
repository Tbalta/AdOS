with System.Machine_Code;     use System.Machine_Code;
with System.Storage_Elements; use System.Storage_Elements;
with config;                  use config;
package body x86.vmm is
    use Standard.ASCII;

    function To_Address (Addr : Page_Address) return System.Address
    is
    begin
        return System.Address (Integer_Address (Addr) * 4_096);
    end To_Address;

    function To_Page_Table_Address (Addr : System.Address) return Page_Table_Address
    is
    begin
        return Page_Table_Address (Integer_Address (Addr) / 4_096);
    end To_Page_Table_Address;

    function To_Page_Directory_Address (Addr : System.Address) return Page_Directory_Address
    is
    begin
        return Page_Directory_Address (Integer_Address (Addr) / 4_096);
    end To_Page_Directory_Address;

    function To_Page_Address (Addr : System.Address) return Page_Address
    is
    begin
        return Page_Address (Integer_Address (Addr) / 4_096);
    end To_Page_Address;


    procedure Enable_Paging is
    begin
        Asm ("movl %%cr0, %%eax" & LF & HT & "or $0x80000000, %%eax" & LF &
            HT & "movl %%eax, %%cr0",
            Volatile => True);
    end Enable_Paging;

    procedure Disable_Paging is
    begin
        Asm ("mov %%cr0, %%eax" & LF & "and $0x7FFFFFFF, %%eax" & LF &
            "mov %%eax, %%cr0" & LF,
            Volatile => True);
    end Disable_Paging;

    function Create_CR3 return CR3_register is
        CR3 : CR3_register;
    begin
        --  Used to allocate Page Directory table
        CR3.Address := To_Page_Address (Allocate_Page);
        CR3.PCD     := True;
        CR3.PWT     := True;

        --  Init the Page Directory
        declare
            PD : Page_Directory_Access :=
               To_Page_Directory (To_Address (CR3.Address));
        begin
            PD.all := Page_Directory'(others => (others => <>));
        end;

        return CR3;
    end Create_CR3;

    procedure Load_CR3 (CR3 : CR3_register) is
    begin
        Asm ("movl %0, %%eax" & LF & "movl %%eax, %%cr3" & LF,
            Inputs => CR3_register'Asm_Input ("a", CR3), Volatile => True);
    end Load_CR3;

    procedure Create_Page_Table
       (PD : Page_Directory_Access; PD_Index : Page_Directory_Index)
    is
    begin
        PD.all (PD_Index).Present         := True;
        PD.all (PD_Index).Read_Write      := True;
        PD.all (PD_Index).User_Supervisor := False;
        PD.all (PD_Index).Write_Through   := False;
        PD.all (PD_Index).Cache_Disable   := False;
        PD.all (PD_Index).Accessed        := False;
        PD.all (PD_Index).Page_Size       := False;
        PD.all (PD_Index).Global          := False;
        PD.all (PD_Index).Address         := To_Page_Address (Allocate_Page);

        declare
            PT : Page_Table_Access :=
               To_Page_Table (To_Address (PD.all (PD_Index).Address));
        begin
            PT.all := Page_Table'(others => (others => <>));
        end;
    end Create_Page_Table;

    procedure Map_Page_Table_Entry
       (Page_Table : Page_Table_Access; Page_Table_Start : Page_Table_Index;
        Address    : Page_Address)
    is
    begin
        Page_Table.all (Page_Table_Start).Present         := True;
        Page_Table.all (Page_Table_Start).Read_Write      := True;
        Page_Table.all (Page_Table_Start).User_Supervisor := False;
        Page_Table.all (Page_Table_Start).Write_Through   := False;
        Page_Table.all (Page_Table_Start).Cache_Disable   := False;
        Page_Table.all (Page_Table_Start).Accessed        := False;
        Page_Table.all (Page_Table_Start).Page_Size       := False;
        Page_Table.all (Page_Table_Start).Global          := False;
        Page_Table.all (Page_Table_Start).Address         := Address;
    end Map_Page_Table_Entry;

    procedure Next
       (Page_Directory_Start : in out Page_Directory_Index;
        Page_Table_Start     : in out Page_Table_Index)
    is
    begin
        if Page_Table_Start = Page_Table'Last then
            Page_Table_Start     := 0;
            Page_Directory_Start := Page_Directory_Start + 1;
        else
            Page_Table_Start := Page_Table_Start + 1;
        end if;
    end Next;

    procedure Map_Range
       (Page_Directory             : Page_Directory_Access;
        Page_Directory_Start       : Page_Directory_Index;
        Page_Table_Start           : Page_Table_Index;
        Start_Address, End_Address : Physical_Address)
    is
        PT_Count : Natural :=
           (Natural (To_Integer (End_Address - Start_Address)) + 4_095) /
           4_096;

        PD_Index       : Page_Directory_Index := Page_Directory_Start;
        PT_Index       : Page_Table_Index     := Page_Table_Start;
        Address_To_Map : Physical_Address     := Start_Address;
    begin
        for i in 1 .. PT_Count loop
            if not Page_Directory.all (PD_Index).Present then
                Create_Page_Table (Page_Directory, PD_Index);
            end if;

            Map_Page_Table_Entry
               (To_Page_Table (Page_Directory.all (PD_Index)), PT_Index,
                To_Page_Address (Address_To_Map));
            Next (PD_Index, PT_Index);
            Address_To_Map := Address_To_Map + Storage_Offset (4_096);
        end loop;

    end Map_Range;

    procedure Identity_Map (CR3 : CR3_register) is
        PD : Page_Directory_Access := To_Page_Directory (To_Address (CR3.Address));
        Address_Breakdown : Virtual_Address_Break :=
           To_Virtual_Address_Break (Kernel_Start);
    begin

        -- Identity map the kernel
        Map_Range
           (PD, Address_Breakdown.Directory, Address_Breakdown.Table,
            Kernel_Start, Kernel_End);
    end Identity_Map;

end x86.vmm;
