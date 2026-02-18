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


   function To_Virtual_Address (address : Physical_Address) return Virtual_Address;
   function To_Physical_Address (address : Virtual_Address) return Physical_Address;

private
   Paging_Enabled : Boolean := True;
   PAGE_SIZE      : constant Storage_Count := 4096;
   type Page_Index     is mod 2 ** 9;


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

  type Page_Entry is record
      Present         : Boolean := False;
      Is_Writable     : Boolean := False;
      Is_Usermode     : Boolean := False;
      Write_Through   : Boolean := False;
      Cache_Disable   : Boolean := False;
      Accessed        : Boolean := False;
      Page_Size       : Boolean := False;
      Address         : Page_Address;
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

   type Page_Map_Level_4_Entry is new Page_Entry;
   type Page_Map_Level_4_Entry_Access is access all Page_Map_Level_4_Entry;
  
   type Page_Map_Level_3_Entry is new Page_Entry;
   type Page_Map_Level_3_Entry_Access is access all Page_Map_Level_3_Entry;

   type Page_Map_Level_2_Entry is new Page_Entry;
   type Page_Map_Level_2_Entry_Access is access all Page_Map_Level_2_Entry;

   type Page_Map_Level_1_Entry is new Page_Entry;
   type Page_Map_Level_1_Entry_Access is access all Page_Map_Level_1_Entry;

   subtype Virtual_Address_Offset is Storage_Offset range 0 .. 2 ** 12 - 1;

   type Virtual_Address_Break is record
      Offset     : Virtual_Address_Offset;
      PML1_Index : Page_Index;
      PML2_Index : Page_Index;
      PML3_Index : Page_Index;
      PML4_Index : Page_Index;
      end record
      with Size => 64;

   for Virtual_Address_Break use
     record
       Offset     at 0 range 0 .. 11;
       PML1_Index at 0 range 12 .. 20;
       PML2_Index at 0 range 21 .. 29;
       PML3_Index at 0 range 30 .. 38;
       PML4_Index at 0 range 39 .. 47;
     end record;
   function To_Virtual_Address_Break is new
     Ada.Unchecked_Conversion (Source => Virtual_Address, Target => Virtual_Address_Break);
   function From_Virtual_Address_Break is new
     Ada.Unchecked_Conversion (Source => Virtual_Address_Break, Target => Virtual_Address);

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

   package PML4_Conversion is new System.Address_To_Access_Conversions (Page_Map_Level_4);
   package PML3_Conversion is new System.Address_To_Access_Conversions (Page_Map_Level_3);
   package PML2_Conversion is new System.Address_To_Access_Conversions (Page_Map_Level_2);
   package PML1_Conversion is new System.Address_To_Access_Conversions (Page_Map_Level_1);

  function To_PML4_Access (System_Address : Virtual_Address) return Page_Map_Level_4_Access is (Page_Map_Level_4_Access (PML4_Conversion.To_Pointer (System.Address (System_Address))));
  function To_PML3_Access (System_Address : Virtual_Address) return Page_Map_Level_3_Access is (Page_Map_Level_3_Access (PML3_Conversion.To_Pointer (System.Address (System_Address))));
  function To_PML2_Access (System_Address : Virtual_Address) return Page_Map_Level_2_Access is (Page_Map_Level_2_Access (PML2_Conversion.To_Pointer (System.Address (System_Address))));
  function To_PML1_Access (System_Address : Virtual_Address) return Page_Map_Level_1_Access is (Page_Map_Level_1_Access (PML1_Conversion.To_Pointer (System.Address (System_Address))));

  function To_PML4_Access (System_Address : Physical_Address) return Page_Map_Level_4_Access is (To_PML4_Access (To_Virtual_Address (System_Address)));
  function To_PML3_Access (System_Address : Physical_Address) return Page_Map_Level_3_Access is (To_PML3_Access (To_Virtual_Address (System_Address)));
  function To_PML2_Access (System_Address : Physical_Address) return Page_Map_Level_2_Access is (To_PML2_Access (To_Virtual_Address (System_Address)));
  function To_PML1_Access (System_Address : Physical_Address) return Page_Map_Level_1_Access is (To_PML1_Access (To_Virtual_Address (System_Address)));

   type Page_Count is new Long_Long_Long_Integer range 0 .. (2**64 - 1);
   Page_Per_PML1 : constant Page_Count := Page_Map_Level_1'Length;
   Page_Per_PML2 : constant Page_Count := Page_Map_Level_2'Length * Page_Per_PML1;
   Page_Per_PML3 : constant Page_Count := Page_Map_Level_3'Length * Page_Per_PML2;
   Page_Per_PML4 : constant Page_Count := Page_Map_Level_4'Length * Page_Per_PML3;
   pragma Assert (Page_Per_PML1 = 512);
   pragma Assert (Page_Per_PML2 = 512 * 512);
   pragma Assert (Page_Per_PML3 = 512 * 512 * 512);
   pragma Assert (Page_Per_PML4 = 512 * 512 * 512 * 512);




   Null_Address_Break : constant Virtual_Address_Break := 
     (PML4_Index => 0,
      PML3_Index => 0,
      PML2_Index => 0,
      PML1_Index => 0,
      Offset     => 0);

   function To_Address (Addr : Page_Address) return Physical_Address;

   function To_Page_Address (Addr : Physical_Address) return Page_Address;
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
     (CR3           : CR3_register;
      Destination   : Virtual_Address_Break;
      Free_Page     : Boolean)
      with Pre => not Paging_Enabled,
           Post => Paging_Enabled'Old = Paging_Enabled; 

   
   function Find_Next_Space
     (CR3 : CR3_register; Size : Storage_Count; Start : System.Address) return Virtual_Address_Break
      with Pre => not Paging_Enabled,
           Post => Paging_Enabled'Old = Paging_Enabled;

   function Is_Range_Mapped (CR3 : CR3_Register; Address : Virtual_Address; Size : Storage_Count) return Boolean
      with Pre => not Paging_Enabled,
           Post => Paging_Enabled'Old = Paging_Enabled;

   Last_Virtual_Address_Break : constant Virtual_Address_Break :=
     (PML4_Index => Page_Index'Last,
      PML3_Index => Page_Index'Last,
      PML2_Index => Page_Index'Last,
      PML1_Index => Page_Index'Last,
      Offset     => Virtual_Address_Offset'Last);

   Kernel_CR3        : CR3_register;
   Process_CR3        : CR3_register;
   procedure Next (Address : in out Virtual_Address_Break);

  function Is_Mapped
     (CR3: CR3_Register; Destination : Virtual_Address_Break) return Boolean;
     function Get_Page_Number (Address : Virtual_Address_Break) return Page_Count;

end x86.vmm;
