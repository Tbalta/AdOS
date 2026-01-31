------------------------------------------------------------------------------
--                                 X86.VMM                                  --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
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

   type CR3_Register is private;

   -----------------------
   -- Is_Paging_Enabled --
   -----------------------
   function Is_Paging_Enabled return Boolean;
   
   -------------------
   -- Enable_Paging --
   -------------------
   procedure Enable_Paging
      with Post => Is_Paging_Enabled;

   --------------------
   -- Disable_Paging --
   --------------------
   procedure Disable_Paging
      with Post => not Is_Paging_Enabled;


   ----------------
   -- Create_CR3 --
   ----------------
   function Create_CR3 return CR3_register;
   
   --------------
   -- Load_CR3 --
   --------------
   procedure Load_CR3 (CR3 : CR3_register);

   ---------------------
   -- Get_Current_CR3 --
   ---------------------
   function Get_Current_CR3 return CR3_register;
   function Get_Process_CR3 return CR3_register;
   
   --------------------
   -- Get_Kernel_CR3 --
   --------------------
   function Get_Kernel_CR3 return CR3_register;
   
   --------------------
   -- Set_Kernel_CR3 --
   --------------------
   procedure Set_Kernel_CR3 (CR3 : CR3_register);
   
   procedure Set_Process_CR3 (CR3 : CR3_register);
   ---------------------------
   -- Enable_Kernel_Mapping --
   ---------------------------
   procedure Enable_Kernel_Mapping;
   procedure Print_Mapped_Memory (CR3 : CR3_Register);

   

   ------------------
   -- Identity_Map --
   ------------------
   procedure Identity_Map (CR3 : CR3_register)
      with Post => Is_Paging_Enabled'Old = Is_Paging_Enabled;
   
   ------------------
   -- Kernel_Alloc --
   ------------------
   function Kernel_Alloc
     (CR3         : CR3_register;
      Size        : Storage_Count;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Virtual_Address
         with Post => Is_Paging_Enabled'Old = Is_Paging_Enabled;

   ------------------
   -- Memory_Unmap --
   ------------------
   procedure Memory_Unmap
     (CR3 : CR3_register; Address : System.Address; Size : Storage_Count; Free_Page : Boolean)
     with Post => Is_Paging_Enabled'Old = Is_Paging_Enabled;
   function Process_To_Process_Map
     (Source_CR3     : CR3_register;
      Source_Address : Virtual_Address;
      Dest_CR3       : CR3_register;
      Size           : Storage_Count;
      Hint           : Virtual_Address := System.Null_Address) return Virtual_Address;

private
   Paging_Enabled : Boolean := False;

   type Page_Address is range 0 .. 2 ** 20 - 1;
   subtype Page_Table_Address is Page_Address;
   subtype Page_Directory_Address is Page_Address;

   type CR3_register is record
      PWT     : Boolean;
      PCD     : Boolean;
      Address : Page_Directory_Address;
   end record
   with Size => 64;
   for CR3_register use
     record
       PWT at 0 range 3 .. 3;
       PCD at 0 range 4 .. 4;
       Address at 0 range 12 .. 63;
     end record;


   type Page_Table_Entry is record
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
   for Page_Table_Entry use
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

   type Page_Directory_Entry is record
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
   for Page_Directory_Entry use
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

   type Page_Directory_Index is mod 2 ** 10;
   type Page_Table_Index     is mod 2 ** 10;
   subtype Virtual_Address_Offset is Storage_Offset range 0 .. 2 ** 12 - 1;

   type Virtual_Address_Break is record
      Directory : Page_Directory_Index;
      Table     : Page_Table_Index;
      Offset    : Virtual_Address_Offset;
      end record
      with Size => 32;

   for Virtual_Address_Break use
     record
       Directory at 0 range 22 .. 31;
       Table at 0 range 12 .. 21;
       Offset at 0 range 0 .. 11;
     end record;
   function To_Virtual_Address_Break is new
     Ada.Unchecked_Conversion (Source => Virtual_Address, Target => Virtual_Address_Break);
   function From_Virtual_Address_Break is new
     Ada.Unchecked_Conversion (Source => Virtual_Address_Break, Target => Virtual_Address);

   type Page_Table is array (Page_Table_Index) of aliased Page_Table_Entry
      with Pack => True,
           Component_Size => 32,
           Size => 1024  * 32;

   type Page_Directory is
     array (Page_Directory_Index range 0 .. 1_023) of aliased Page_Directory_Entry
   with Pack => True, Size => 4_096 * 8;

   package Address_to_Page_Table is new System.Address_To_Access_Conversions (Page_Table);
   subtype Page_Table_Access is Address_to_Page_Table.Object_Pointer;

   package Address_to_Page_Directory is new System.Address_To_Access_Conversions (Page_Directory);
   subtype Page_Directory_Access is Address_to_Page_Directory.Object_Pointer;
   function To_Page_Directory (Addr : Physical_Address) return Page_Directory_Access
   is (Address_to_Page_Directory.To_Pointer (Addr));

   Null_Address_Break : constant Virtual_Address_Break := (Directory => 0, Table => 0, Offset => 0);

   function To_Address (Addr : Page_Address) return System.Address;

   function To_Page_Table_Address (Addr : System.Address) return Page_Table_Address;
   function To_Page_Directory_Address (Addr : System.Address) return Page_Directory_Address;
   function To_Page_Address (Addr : System.Address) return Page_Address;
   function Can_Fit
     (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count) return Boolean
      with Pre => not Paging_Enabled,
           Post => Paging_Enabled'Old = Paging_Enabled;
   function Alloc
     (CR3         : CR3_register;
      Address     : Virtual_Address;
      Data_Size   : Storage_count;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Boolean
      with Pre => not Paging_Enabled,
           Post => Paging_Enabled'Old = Paging_Enabled; 
   
   procedure Unmap_Page
     (Page_Directory       : Page_Directory_Access;
      Page_Directory_Start : Page_Directory_Index;
      Page_Table_Start     : Page_Table_Index;
      Free_Page            : Boolean)
      with Pre => not Paging_Enabled,
           Post => Paging_Enabled'Old = Paging_Enabled; 

   
   function Find_Next_Space
     (CR3 : CR3_register; Size : Storage_Count; Start : System.Address) return Virtual_Address_Break
      with Pre => not Paging_Enabled,
           Post => Paging_Enabled'Old = Paging_Enabled;

   function Is_Range_Mapped (CR3 : CR3_Register; Address : Virtual_Address; Size : Storage_Count) return Boolean
      with Pre => not Paging_Enabled,
           Post => Paging_Enabled'Old = Paging_Enabled;

   function To_Page_Table (Addr : Physical_Address) return Page_Table_Access
   is (Address_to_Page_Table.To_Pointer (Addr));
   function To_Page_Table (PDE : Page_Directory_Entry) return Page_Table_Access
   is (To_Page_Table (To_Address (PDE.Address)));
   function To_Page_Table_Access (Page_Table_Addr : Page_Table_Address) return Page_Table_Access
   is (Address_to_Page_Table.To_Pointer (To_Address (Page_Table_Addr)));

   Last_Virtual_Address_Break : constant Virtual_Address_Break :=
     (Directory => Page_Directory_Index'Last, Table => Page_Table_Index'Last, Offset => 0);

   Kernel_CR3        : CR3_register;
   Process_CR3        : CR3_register;
   procedure Next
     (Page_Directory_Start : in out Page_Directory_Index;
      Page_Table_Start     : in out Page_Table_Index);


end x86.vmm;
