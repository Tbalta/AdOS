with Interfaces; use Interfaces;
with System;     use System;
with System.Address_To_Access_Conversions;
with x86.pmm;    use x86.pmm;
with Ada.Unchecked_Conversion;
package x86.vmm is
    pragma Preelaborate;

    procedure Enable_Paging;
    procedure Disable_Paging;

    type Page_Directory_Index is mod 2**10;
    type Page_Table_Index is mod 2**10;
    type Virtual_Address_Offset is mod 2**12;

    type Page_Address is mod 2**20;
    subtype Page_Table_Address is Page_Address;
    subtype Page_Directory_Address is Page_Address;

    function To_Address (Addr : Page_Address) return System.Address;

    function To_Page_Table_Address (Addr : System.Address) return Page_Table_Address;
    function To_Page_Directory_Address (Addr : System.Address) return Page_Directory_Address;
    function To_Page_Address (Addr : System.Address) return Page_Address;

    subtype Virtual_Address is System.Address;

    type Page_Table_Entry is record
        Present         : Boolean;
        Read_Write      : Boolean;
        User_Supervisor : Boolean;
        Write_Through   : Boolean;
        Cache_Disable   : Boolean;
        Accessed        : Boolean;
        Dirty           : Boolean;
        Page_Size       : Boolean;
        Global          : Boolean;
        Address         : Page_Address;
    end record;

    for Page_Table_Entry use record
        Present         at 0 range  0 ..  0;
        Read_Write      at 0 range  1 ..  1;
        User_Supervisor at 0 range  2 ..  2;
        Write_Through   at 0 range  3 ..  3;
        Cache_Disable   at 0 range  4 ..  4;
        Accessed        at 0 range  5 ..  5;
        Dirty           at 0 range  6 ..  6;
        Page_Size       at 0 range  7 ..  7;
        Global          at 0 range  8 ..  8;
        Address         at 0 range 12 .. 31;
    end record;

    type Page_Directory_Entry is record
        Present         : Boolean;
        Read_Write      : Boolean;
        User_Supervisor : Boolean;
        Write_Through   : Boolean;
        Cache_Disable   : Boolean;
        Accessed        : Boolean;
        Page_Size       : Boolean;
        Global          : Boolean;
        Address         : Page_Table_Address;
    end record;

    for Page_Directory_Entry use record
        Present         at 0 range  0 ..  0;
        Read_Write      at 0 range  1 ..  1;
        User_Supervisor at 0 range  2 ..  2;
        Write_Through   at 0 range  3 ..  3;
        Cache_Disable   at 0 range  4 ..  4;
        Accessed        at 0 range  5 ..  5;
        Page_Size       at 0 range  7 ..  7;
        Global          at 0 range  8 ..  8;
        Address         at 0 range 12 .. 31;
    end record;

    type Page_Table is
       array
          (Page_Table_Index range 0 .. 1_023) of aliased Page_Table_Entry with
       Pack => True, Size => 4_096 * 8;

    type Page_Directory is
       array (Page_Directory_Index range 0 .. 1_023) of aliased Page_Directory_Entry with
       Pack => True, Size => 4_096 * 8;

    package Address_to_Page_Table is new System.Address_To_Access_Conversions
       (Page_Table);
    subtype Page_Table_Access is Address_to_Page_Table.Object_Pointer;

    function To_Page_Table (Addr : Physical_Address) return Page_Table_Access is
       (Address_to_Page_Table.To_Pointer (Addr));
    function To_Page_Table
       (PDE : Page_Directory_Entry) return Page_Table_Access is
       (To_Page_Table (To_Address (PDE.Address)));

    package Address_to_Page_Directory is new System
       .Address_To_Access_Conversions
       (Page_Directory);
    subtype Page_Directory_Access is Address_to_Page_Directory.Object_Pointer;
    function To_Page_Directory
       (Addr : Physical_Address) return Page_Directory_Access is
       (Address_to_Page_Directory.To_Pointer (Addr));

    type CR3_register is record
        PWT     : Boolean;
        PCD     : Boolean;
        Address : Page_Directory_Address;
    end record with
       Size => 32;

    for CR3_register use record
        PWT     at 0 range  3 ..  3;
        PCD     at 0 range  4 ..  4;
        Address at 0 range 12 .. 31;
    end record;

    type Virtual_Address_Break is record
        Directory : Page_Directory_Index;
        Table     : Page_Table_Index;
        Offset    : Virtual_Address_Offset;
    end record with
       Size => 32;
    for Virtual_Address_Break use record
        Directory at 0 range 22 .. 31;
        Table     at 0 range 12 .. 21;
        Offset    at 0 range  0 .. 11;
    end record;

    function To_Virtual_Address_Break is new Ada.Unchecked_Conversion
       (Source => System.Address, Target => Virtual_Address_Break);

    function Create_CR3 return CR3_register;
    procedure Load_CR3 (CR3 : CR3_register);
    procedure Identity_Map (CR3 : CR3_register);
end x86.vmm;
