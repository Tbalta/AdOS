with SERIAL;
with System.Machine_Code;     use System.Machine_Code;
with System.Storage_Elements; use System.Storage_Elements;
with config;                  use config;
package body x86.vmm is
    use Standard.ASCII;

    function To_Address (Addr : Page_Address) return System.Address is
    begin
        return System.Address (Integer_Address (Addr) * 4_096);
    end To_Address;

    function To_Page_Table_Address
       (Addr : System.Address) return Page_Table_Address
    is
    begin
        return Page_Table_Address (Integer_Address (Addr) / 4_096);
    end To_Page_Table_Address;

    function To_Page_Directory_Address
       (Addr : System.Address) return Page_Directory_Address
    is
    begin
        return Page_Directory_Address (Integer_Address (Addr) / 4_096);
    end To_Page_Directory_Address;

    function To_Page_Address (Addr : System.Address) return Page_Address is
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
            PD.all := Page_Directory'(others => (Present => False, others => <>));
        end;

        return CR3;
    end Create_CR3;

    procedure Load_CR3 (CR3 : CR3_register) is
    begin
        Asm ("movl %0, %%eax" & LF & "movl %%eax, %%cr3" & LF,
            Inputs => CR3_register'Asm_Input ("a", CR3), Volatile => True);
    end Load_CR3;

    procedure Create_Page_Table
       (PD :     Page_Directory_Access; PD_Index : Page_Directory_Index;
        PT : out Page_Table_Access)
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

        PT     := To_Page_Table (To_Address (PD.all (PD_Index).Address));
        PT.all := Page_Table'(others => (others => <>));
    end Create_Page_Table;

    procedure Create_Page_Table
       (PD : Page_Directory_Access; PD_Index : Page_Directory_Index)
    is
        PT : Page_Table_Access;
    begin
        Create_Page_Table (PD, PD_Index, PT);
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
        SERIAL.send_line
           ("Mapping range" & Start_Address'Image & " -" & End_Address'Image);
         SERIAL.send_line
           ("Number of pages to map: " & Natural'Image (PT_Count));
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
        PD                : Page_Directory_Access :=
           To_Page_Directory (To_Address (CR3.Address));
        Address_Breakdown : Virtual_Address_Break :=
           To_Virtual_Address_Break (Kernel_Start);
    begin

        -- Identity map the kernel
        SERIAL.send_line ("Identity map kernel" & Kernel_Start'Image & " -"  &Kernel_End'Image);
        Map_Range
           (PD, Address_Breakdown.Directory, Address_Breakdown.Table,
            Kernel_Start, Kernel_End);
    end Identity_Map;

    function Can_Fit
       (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count)
        return Boolean
    is
        PD                : Page_Directory_Access := To_Page_Directory (To_Address (CR3.Address));
        PT : Page_Table_Access;
        Address_Breakdown : Virtual_Address_Break :=
           To_Virtual_Address_Break (Address);
        To_Fit            : Storage_Count         := Size;
    begin
        for PD_Index in Address_Breakdown.Directory .. Page_Directory'Last loop
            exit when To_Fit = 0;
            if not PD (PD_Index).Present then
                To_Fit :=
                   To_Fit -
                   Storage_Count'Min (To_Fit, Storage_Count (Page_Table'Length * PMM_PAGE_SIZE));
            else
                PT := To_Page_Table (To_Address (PD (PD_Index).Address));
                for PT_Index in Address_Breakdown.Table .. Page_Table'Last loop
                    if not PT (PT_Index).Present then
                        To_Fit := To_Fit - Storage_Count'Min (To_Fit, PMM_PAGE_SIZE);
                    else
                        return To_Fit = 0;
                    end if;
                end loop;
                Address_Breakdown.Table := 0;
            end if;
        end loop;
        return To_Fit = 0;
    end Can_Fit;

    function Map_Data
       (CR3  : in out CR3_register; Address : Virtual_Address;
        Data : in     Data_Type) return Boolean
    is
        --  Returns True if the mapping was successful and False otherwise

        PD                : Page_Directory_Access :=
           To_Page_Directory (To_Address (CR3.Address));
        PT                : Page_Table_Access;
        Address_Breakdown : Virtual_Address_Break :=
           To_Virtual_Address_Break (Address);
        Data_Size         : Storage_Count         := Data'Size / Storage_Unit;

        procedure memcpy
           (dest : System.Address; src : System.Address; size : Natural);
        pragma Import (C, memcpy, "memcpy");

        PD_Entry :
           Page_Directory_Entry renames PD (Address_Breakdown.Directory);
        PT_Entry : Page_Table_Entry renames PT (Address_Breakdown.Table);

        Data_Buffer : System.Address := Data'Address;

    begin
        if not Can_Fit (CR3, Address, Data_Size) then
            return False;
        end if;

        while Data_Size > 0 loop
            if not PD.all (Address_Breakdown.Directory).Present then
                Create_Page_Table (PD, Address_Breakdown.Directory);
            end if;

            PT := To_Page_Table (To_Address (PD_Entry.Address));

            PT_Entry.Present         := True;
            PT_Entry.Read_Write      := True;
            PT_Entry.User_Supervisor := False;
            PT_Entry.Write_Through   := False;
            PT_Entry.Cache_Disable   := False;
            PT_Entry.Accessed        := False;
            PT_Entry.Page_Size       := False;
            PT_Entry.Global          := False;
            PT_Entry.Address         := To_Page_Address (Allocate_Page);

            --  Map the data
            declare
                Data_To_Map_Size : Storage_Count  :=
                   Storage_Count'Min
                      (Data_Size,
                       Virtual_Address_Offset'Last - Address_Breakdown.Offset);
                Destination      : System.Address :=
                   To_Address (PT_Entry.Address) +
                   Storage_Offset (Address_Breakdown.Offset);
            begin
                memcpy
                   (dest => Destination, src => Data_Buffer,
                    size => Integer (Data_To_Map_Size));
                Data_Size   := Data_Size - Data_To_Map_Size;
                Data_Buffer := Data_Buffer + Storage_Offset (Data_To_Map_Size);
            end;
            Address_Breakdown.Offset := 0;
            Next (Address_Breakdown.Directory, Address_Breakdown.Table);

        end loop;

        return True;
    end Map_Data;

end x86.vmm;
