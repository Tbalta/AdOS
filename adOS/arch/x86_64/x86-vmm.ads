------------------------------------------------------------------------------
--                                 X86.VMM                                  --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with Interfaces;              use Interfaces;
with Limine;
with System;                  use System;
with System.Address_To_Access_Conversions;
with x86;
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
   type Page_Type is (Not_Mapped, Page_4KB, Page_2MB, Page_1GB);
   type Entry_Level is (Entry_Level_1, Entry_Level_2, Entry_Level_3, Entry_Level_4);

   -----------------------
   -- Paging Operations --
   -----------------------
   function Is_Paging_Enabled return Boolean;
   procedure Enable_Paging;
   procedure Disable_Paging;

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
   procedure Print_PLM4 (CR3 : CR3_Register);

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
   function To_Physical_Address (address : Virtual_Address) return Physical_Address;

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




   Paging_Enabled  : Boolean := True;
   PAGE_SIZE       : constant Storage_Count := 4096;
   PAGE_SIZE_2MB   : constant Storage_Count := 2 ** 21;
   PAGE_SIZE_1GB   : constant Storage_Count := 2 ** 30;
   PAGE_SIZE_512GB : constant Storage_Count := 2 ** 39;
   type Page_Index     is mod 2 ** 9;


   type Page_Address is range 0 .. 2 ** 40 - 1;
   type Page_Address_2MB is range 0 .. 2 ** 31 - 1;
   type Page_Address_1GB is range 0 .. 2 ** 22 - 1;

   type CR3_register is record
      PWT     : Boolean;
      PCD     : Boolean;
      Address : Page_Address;
   end record
   with Size => 64;
   for CR3_register use
     record
       PWT at 0 range 3 .. 3;
       PCD at 0 range 4 .. 4;
       Address at 0 range 12 .. 63;
     end record;

   type Page_Entry is record
      Present         : Boolean := False;
      Is_Writable     : Boolean := False;
      Is_Usermode     : Boolean := False;
      Write_Through   : Boolean := False;
      Cache_Disable   : Boolean := False;
      Accessed        : Boolean := False;
      Page_Size       : Boolean := False;
      Address         : Page_Address := 0;
      Execute_Disable : Boolean := False;
   end record
      with  Size => 64,
            Object_Size => 64;
   --!format off
   for Page_Entry use
     record
       Present       at 0 range 0 .. 0;
       Is_Writable   at 0 range 1 .. 1;
       Is_Usermode   at 0 range 2 .. 2;
       Write_Through at 0 range 3 .. 3;
       Cache_Disable at 0 range 4 .. 4;
       Accessed      at 0 range 5 .. 5;
       Page_Size     at 0 range 7 .. 7;
       Address       at 0 range 12 .. 52;
       Execute_Disable at 0 range 63 .. 63;
     end record;
   --!format on

  type Page_Map_Level_2_Entry (Page_Size : Boolean := False) is record
      Present         : Boolean := False;
      Is_Writable     : Boolean := False;
      Is_Usermode     : Boolean := False;
      Write_Through   : Boolean := False;
      Cache_Disable   : Boolean := False;
      Accessed        : Boolean := False;

      Execute_Disable : Boolean := False;
      case Page_Size is
         when True =>
            Address_2MB : Page_Address_2MB;
         when False =>
            Address : Page_Address;
      end case;
   end record
      with  Size => 64,
            Object_Size => 64;
  for Page_Map_Level_2_Entry use
     record
       Present       at 0 range 0 .. 0;
       Is_Writable   at 0 range 1 .. 1;
       Is_Usermode   at 0 range 2 .. 2;
       Write_Through at 0 range 3 .. 3;
       Cache_Disable at 0 range 4 .. 4;
       Accessed      at 0 range 5 .. 5;
       Page_Size     at 0 range 7 .. 7;
       Address_2MB   at 0 range 21 .. 51;
       Address  at 0 range 12 .. 51;
       Execute_Disable at 0 range 63 .. 63;
     end record;
  type Page_Map_Level_3_Entry (Page_Size : Boolean := False) is record
      Present         : Boolean := False;
      Is_Writable     : Boolean := False;
      Is_Usermode     : Boolean := False;
      Write_Through   : Boolean := False;
      Cache_Disable   : Boolean := False;
      Accessed        : Boolean := False;

      Execute_Disable : Boolean := False;
      case Page_Size is
         when True =>
            Address_1GB : Page_Address_1GB;
         when False =>
            Address : Page_Address;
      end case;
   end record
      with  Size => 64,
            Object_Size => 64;
  for Page_Map_Level_3_Entry use
     record
       Present       at 0 range 0 .. 0;
       Is_Writable   at 0 range 1 .. 1;
       Is_Usermode   at 0 range 2 .. 2;
       Write_Through at 0 range 3 .. 3;
       Cache_Disable at 0 range 4 .. 4;
       Accessed      at 0 range 5 .. 5;
       Page_Size     at 0 range 7 .. 7;
       Address_1GB   at 0 range 30 .. 51;
       Address       at 0 range 12 .. 51;
       Execute_Disable at 0 range 63 .. 63;
     end record;


   type Page_Map_Level_4_Entry is new Page_Entry;
   type Page_Map_Level_4_Entry_Access is access all Page_Map_Level_4_Entry;
  
   type Page_Map_Level_3_Entry_Access is access all Page_Map_Level_3_Entry;

   type Page_Map_Level_2_Entry_Access is access all Page_Map_Level_2_Entry;

   type Page_Map_Level_1_Entry is new Page_Entry;
   type Page_Map_Level_1_Entry_Access is access all Page_Map_Level_1_Entry;

   subtype Virtual_Address_Offset is Storage_Offset range 0 .. 2 ** 12 - 1;

   type Page_Map_Level_4 is array (Page_Index) of aliased Page_Map_Level_4_Entry
      with Pack => True,
           Component_Size => 64,
           Size => PAGE_SIZE * 8;
    type Page_Map_Level_4_Access is access all Page_Map_Level_4;
   type Page_Map_Level_3 is array (Page_Index) of aliased Page_Map_Level_3_Entry
      with Pack => True,
           Component_Size => 64,
           Size => PAGE_SIZE * 8;
    type Page_Map_Level_3_Access is access all Page_Map_Level_3;
   type Page_Map_Level_2 is array (Page_Index) of aliased Page_Map_Level_2_Entry
      with Pack => True,
           Component_Size => 64,
           Size => PAGE_SIZE * 8;
    type Page_Map_Level_2_Access is access all Page_Map_Level_2;
   type Page_Map_Level_1 is array (Page_Index) of aliased Page_Map_Level_1_Entry
      with Pack => True,
           Component_Size => 64,
           Size => PAGE_SIZE * 8;
    type Page_Map_Level_1_Access is access all Page_Map_Level_1;

   function To_Address (Addr : Page_Address) return Physical_Address is (Physical_Address (Storage_Count (Integer_Address (Addr)) * PAGE_SIZE));
   function To_Address (Addr : Page_Address_2MB)  return Physical_Address is (Physical_Address (Storage_Count (Integer_Address (Addr)) * PAGE_SIZE_2MB));



   type Page_Count is new Long_Long_Long_Integer range 0 .. (2**64 - 1);
   Page_Per_PML1 : constant Page_Count := Page_Map_Level_1'Length;
   Page_Per_PML2 : constant Page_Count := Page_Map_Level_2'Length * Page_Per_PML1;
   Page_Per_PML3 : constant Page_Count := Page_Map_Level_3'Length * Page_Per_PML2;
   Page_Per_PML4 : constant Page_Count := Page_Map_Level_4'Length * Page_Per_PML3;
   pragma Assert (Page_Per_PML1 = 512);
   pragma Assert (Page_Per_PML2 = 512 * 512);
   pragma Assert (Page_Per_PML3 = 512 * 512 * 512);
   pragma Assert (Page_Per_PML4 = 512 * 512 * 512 * 512);

   function To_Page_Address (Addr : Physical_Address) return Page_Address
      with Pre => Storage_Count (Addr) mod Storage_Count (PAGE_SIZE) = 0;
   
   procedure Unmap_Page
      (CR3         : CR3_Register;
         Address     : Virtual_Address;
         Free_Page   : Boolean);


   function Is_Mapped
      (CR3: CR3_Register; Address : Virtual_Address) return Boolean;

   function Get_Offset (CR3 : CR3_Register; Address : Virtual_Address) return Storage_Offset;

   procedure Duplicate_hhdm (Source_CR3, Dest_CR3 : CR3_Register);

   function Is_Last_Address (CR3 : CR3_Register; Address : Virtual_Address) return Boolean;
end x86.vmm;
