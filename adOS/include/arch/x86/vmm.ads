------------------------------------------------------------------------------
--                                 VMM.ADS                                  --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2026 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with x86; use x86;
with x86.vmm; use x86.vmm;
with System.Storage_Elements; use System.Storage_Elements;
with arch;
package vmm is
   pragma Preelaborate;
   
   -------------------------
   -- Computation Utility --
   -------------------------
   function Can_Fit
     (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count) return Boolean;
   function Is_Range_Mapped (CR3 : CR3_Register; Address : Virtual_Address; Size : Storage_Count) return Boolean;


   -----------------------
   -- Mapping Functions --
   -----------------------
   procedure Map_Range
     (CR3                        : CR3_Register;
      Destination                : Virtual_Address;
      Start_Address, End_Address : Physical_Address;
      Is_Writable                : Boolean := False;
      Is_Usermode                : Boolean := False);
   
   function Process_To_Process_Map
     (Source_CR3     : CR3_register;
      Source_Address : Virtual_Address;
      Dest_CR3       : CR3_register;
      Size           : Storage_Count;
      Hint           : Virtual_Address := Virtual_Address'First) return Virtual_Address;


   --------------------------
   -- Allocation Functions --
   --------------------------
   function Alloc_In_Range
     (CR3         : CR3_register;
      Size        : Storage_Count;
      Range_Start, Range_End : Virtual_Address;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Virtual_Address;
   function User_Alloc
     (CR3         : CR3_register;
      Size        : Storage_Count;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Virtual_Address is
         (Alloc_In_Range (CR3 => CR3,
                          Size => Size,
                          Range_Start => Arch.Get_User_Address_Space_Start,
                          Range_End => Arch.Get_User_Address_Space_End,
                          Is_Writable => Is_Writable,
                          Is_Usermode => Is_Usermode));
   function Kernel_Alloc
     (CR3         : CR3_register;
      Size        : Storage_Count;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Virtual_Address is
         (Alloc_In_Range (CR3 => CR3,
                          Size => Size,
                          Range_Start => Arch.Get_Kernel_Address_Space_Start,
                          Range_End => Arch.Get_Kernel_Address_Space_End,
                          Is_Writable => Is_Writable,
                          Is_Usermode => Is_Usermode));
   

   ----------------------------
   -- Deallocation Functions --
   ----------------------------
   procedure Memory_Unmap
     (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count; Free_Page : Boolean)
     with Post => Is_Paging_Enabled'Old = Is_Paging_Enabled;

   -----------------
   -- CR3 Utility --
   -----------------
   function Get_Process_CR3 return CR3_register;
   function Get_Kernel_CR3 return CR3_register;
   procedure Set_Kernel_CR3 (CR3 : CR3_register);
   procedure Set_Process_CR3 (CR3 : CR3_register);
   procedure Enable_Kernel_Mapping;

private
   Kernel_CR3  : CR3_register;
   Process_CR3 : CR3_register;
end vmm;