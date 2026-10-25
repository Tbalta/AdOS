------------------------------------------------------------------------------
--                                 X86.VMM                                  --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with Interfaces;              use Interfaces;
with System;                  use System;
with System.Address_To_Access_Conversions;
with x86.pmm;                 use x86.pmm;
with Ada.Unchecked_Conversion;
with System.Storage_Elements;
use System.Storage_Elements;


--                  +---------------------------------------------+
--  Virtual Address |  DIR (10 bits) |  TBL (10 bits) | OFFSET(12)|
--                  +---------------------------------------------+
--                           |               |              |
--                           |               |              |
--                           v               v              v
--                     (index into)    (index into)   (offset inside
--                    Page Directory     Page Table      4 KB page)
--                           |
--                           |
--             +-------------------------------+
--             |  Page Directory (1024 entries)| <---- Address from CR3.Address * PAGE_SIZE (0x4096)
--             +-------------------------------+
--             | Dir[0] -> points to PT 0      |---+
--             | Dir[1] -> points to PT 1      |---+--+
--             | ...                           |   |  |
--             |                               |   |  |
--             |                               |   |  |
--             +-------------------------------+   |  |
--                                                 |  |
--                                                 v  v
--                                     +---------------------------+
--                                     | Page Table (1024 entries) |
--                                     +---------------------------+
--                                     | PT[0] -> Physical Frame 0 |
--                                     |                           |
--                                     | ...                       |
--                                     |                           |
--                                     +---------------------------+
--                                               |
--                                               |
--                                               v
--                                   +-----------------------+
--                                   | Physical Memory Frame |
--                                   |   (4 KB page)         |
--                                   +-----------------------+
--                                   |   actual RAM data     |
--                                   +-----------------------+




package x86.vmm
is
   pragma Preelaborate;

   type CR3_Register;

   -----------------------
   -- Paging Operations --
   -----------------------
   function Is_Paging_Enabled return Boolean;
   procedure Enable_Paging
      with Post => Is_Paging_Enabled;
   procedure Disable_Paging
      with Post => not Is_Paging_Enabled;


   --------------------
   -- CR3 Operations --
   --------------------
   function Create_CR3 return CR3_register;
   procedure Load_CR3 (CR3 : CR3_register);
   function Get_Current_CR3 return CR3_register;

   
   ---------------------
   -- Logging Utility --
   ---------------------
   procedure Print_Mapped_Memory (CR3 : CR3_Register);
   -- procedure Print_PLM4 (CR3 : CR3_Register);

   
   -------------------
   -- Page counting --
   -------------------
   function Get_Number_Of_Pages (Size : Storage_Count; Offset : Storage_Offset := 0) return Positive;
   function Get_Free_Size (CR3 : CR3_Register; Address : Virtual_Address) return Storage_Count;
   function Get_Allocated_Size (CR3 : CR3_Register; Address : Virtual_Address) return Storage_Count;


   ------------------
   -- Identity_Map --
   ------------------
   procedure Identity_Map (CR3 : CR3_register)
      with Post => Is_Paging_Enabled'Old = Is_Paging_Enabled;


   ------------------------
   -- Address Conversion --
   ------------------------
   function Virtual_To_Physical_Address
     (CR3 : CR3_register; Address : Virtual_Address) return Physical_Address;
   function To_Virtual_Address (address : Physical_Address) return Virtual_Address;
   -- function To_Physical_Address (address : Virtual_Address) return Physical_Address;
   

   ---------------------
   -- Page Allocation --
   ---------------------
   function Alloc
     (CR3         : CR3_register;
      Address     : Virtual_Address;
      Data_Size   : Storage_count;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Boolean;
   
   procedure Map_Physical_Page
     (
      Process              : CR3_Register;
      Destination          : Virtual_Address;
      Address_To_Map       : Physical_Address;
      Is_Writable          : Boolean := False;
      Is_Usermode          : Boolean := False);

-- private
   Paging_Enabled : Boolean := False;
   PAGE_SIZE      : constant Storage_Count := 4096;
   PAGE_SIZE_2MB   : constant Storage_Count := 2 ** 21;

   type Page_Address is range 0 .. 2 ** 20 - 1;
   subtype Page_Table_Address is Page_Address;
   subtype Page_Directory_Address is Page_Address;

   type CR3_register is record
      PWT     : Boolean;
      PCD     : Boolean;
      Address : Page_Directory_Address;
   end record
   with Size => 32;
   for CR3_register use
     record
       PWT at 0 range 3 .. 3;
       PCD at 0 range 4 .. 4;
       Address at 0 range 12 .. 31;
     end record;


   type Page_Map_Level_1_Entry is record
      Present       : Boolean := False;
      Is_Writable   : Boolean := False;
      Is_Usermode   : Boolean := False;
      Write_Through : Boolean := False;
      Cache_Disable : Boolean := False;
      Accessed      : Boolean := False;
      Dirty         : Boolean := False;
      Page_Size     : Boolean := False;
      Global        : Boolean := False;
      Address       : Page_Address;
   end record
      with Size => 32,
           Object_Size => 32;
   --!format off
   for Page_Map_Level_1_Entry use
     record
       Present       at 0 range 0 .. 0;
       Is_Writable   at 0 range 1 .. 1;
       Is_Usermode   at 0 range 2 .. 2;
       Write_Through at 0 range 3 .. 3;
       Cache_Disable at 0 range 4 .. 4;
       Accessed      at 0 range 5 .. 5;
       Dirty         at 0 range 6 .. 6;
       Page_Size     at 0 range 7 .. 7;
       Global        at 0 range 8 .. 8;
       Address       at 0 range 12 .. 31;
     end record;
   --!format on

   type Page_Map_Level_2_Entry is record
      Present       : Boolean := False;
      Is_Writable   : Boolean := False;
      Is_Usermode   : Boolean := False;
      Write_Through : Boolean := False;
      Cache_Disable : Boolean := False;
      Accessed      : Boolean := False;
      Page_Size     : Boolean := False;
      Global        : Boolean := False;
      Address       : Page_Table_Address;
   end record;

   --!format off
   for Page_Map_Level_2_Entry use
     record
       Present       at 0 range 0 .. 0;
       Is_Writable   at 0 range 1 .. 1;
       Is_Usermode   at 0 range 2 .. 2;
       Write_Through at 0 range 3 .. 3;
       Cache_Disable at 0 range 4 .. 4;
       Accessed      at 0 range 5 .. 5;
       Page_Size     at 0 range 7 .. 7;
       Global        at 0 range 8 .. 8;
       Address       at 0 range 12 .. 31;
     end record;
   --!format on

   -- Tood: check this value (maybe it should be 2 ** 9)
   type Page_Index     is mod 2 ** 10;
   subtype Virtual_Address_Offset is Storage_Offset range 0 .. 2 ** 12 - 1;


   --  type Virtual_Address_Break is record
   --     PML2_Index : Page_Index;
   --     PML1_Index     : Page_Index;
   --     Offset    : Virtual_Address_Offset;
   --     end record
   --     with Size => 32;

   --  for Virtual_Address_Break use
   --    record
   --      PML2_Index at 0 range 22 .. 31;
   --      PML1_Index at 0 range 12 .. 21;
   --      Offset at 0 range 0 .. 11;
   --    end record;
   --  function To_Virtual_Address_Break is new
   --    Ada.Unchecked_Conversion (Source => Virtual_Address, Target => Virtual_Address_Break);
   --  function From_Virtual_Address_Break is new
   --    Ada.Unchecked_Conversion (Source => Virtual_Address_Break, Target => Virtual_Address);

   type Page_Map_Level_1 is array (Page_Index) of aliased Page_Map_Level_1_Entry
      with Pack => True,
           Component_Size => 32,
           Size => 1024  * 32;

   type Page_Map_Level_2 is array (Page_Index) of aliased Page_Map_Level_2_Entry
   with Pack => True, Size => 4_096 * 8;

   type Page_Map_Level_1_Access is access all Page_Map_Level_1;
   type Page_Map_Level_1_Entry_Access is access all Page_Map_Level_1_Entry;

   type Page_Map_Level_2_Access is access all Page_Map_Level_2;
   type Page_Map_Level_2_Entry_Access is access all Page_Map_Level_2_Entry;


   type Page_Count is new Natural;
   Page_Per_PML1 : constant Page_Count := Page_Map_Level_1'Length;
   Page_Per_PML2 : constant Page_Count := Page_Map_Level_2'Length * Page_Per_PML1;

   function To_Address (Addr : Page_Address) return Physical_Address;

   function To_Page_Table_Address (Addr : System.Address) return Page_Table_Address;
   function To_Page_Directory_Address (Addr : System.Address) return Page_Directory_Address;
   function To_Page_Address (Addr : Physical_Address) return Page_Address;
   
   procedure Unmap_Page
     (CR3                 : CR3_Register;
      Address : Virtual_Address;
      Free_Page            : Boolean)
      with Pre => not Paging_Enabled,
           Post => Paging_Enabled'Old = Paging_Enabled; 


   procedure Next
     (Page_Directory_Start : in out Page_Index;
      Page_Table_Start     : in out Page_Index);

   function Is_Last_Address (CR3 : CR3_Register; Address : Virtual_Address) return Boolean;
   function Get_Offset (CR3 : CR3_Register; Address : Virtual_Address) return Storage_Offset;


end x86.vmm;