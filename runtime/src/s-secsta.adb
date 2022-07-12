------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--               S Y S T E M . S E C O N D A R Y _ S T A C K                --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--          Copyright (C) 1992-2019, Free Software Foundation, Inc.         --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------
with Interfaces;
pragma Compiler_Unit_Warning;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with System.Address_To_Access_Conversions;
with System.Parameters;       use System.Parameters;
package body System.Secondary_Stack is
   pragma Suppress (All_Checks);
   pragma Suppress (Index_Check);
   package SS_Stack_Ptr_Conv is new System.Address_To_Access_Conversions
     (SS_Stack);

   ------------------------------------
   -- Binder Allocated Stack Support --
   ------------------------------------

   --  When at least one of the following restrictions
   --
   --    No_Implicit_Heap_Allocations
   --    No_Implicit_Task_Allocations
   --
   --  is in effect, the binder creates a static secondary stack pool, where
   --  each stack has a default size. Assignment of these stacks to tasks is
   --  performed by SS_Init. The following variables are defined in this unit
   --  in order to avoid depending on the binder. Their values are set by the
   --  binder.

   Binder_SS_Count : Natural;
   pragma Export (Ada, Binder_SS_Count, "__gnat_binder_ss_count");
   --  The number of secondary stacks in the pool created by the binder

   Binder_Default_SS_Size : Size_Type;
   pragma Export (Ada, Binder_Default_SS_Size, "__gnat_default_ss_size");
   --  The default secondary stack size as specified by the binder. The value
   --  is defined here rather than in init.c or System.Init because the ZFP and
   --  Ravenscar-ZFP run-times lack these locations.

   Binder_Default_SS_Pool : Address;
   pragma Export (Ada, Binder_Default_SS_Pool, "__gnat_default_ss_pool");
   --  The address of the secondary stack pool created by the binder

   --  Binder_Default_SS_Pool_Index : Natural := 0;
   --  Index into the secondary stack pool created by the binder

   -----------------------
   -- Local subprograms --
   -----------------------

   --  Allocate enough space on dynamic secondary stack Stack to fit a request
   --  of size Mem_Size. Addr denotes the address of the first byte of the
   --  allocation.

   procedure Allocate_On_Chunk
     (Stack : SS_Stack_Ptr; Prev_Chunk : SS_Chunk_Ptr; Chunk : SS_Chunk_Ptr;
      Byte  : Memory_Index; Mem_Size : Memory_Size; Addr : out Address);
   pragma Inline (Allocate_On_Chunk);
   --  Allocate enough space on chunk Chunk to fit a request of size Mem_Size.
   --  Stack is the owner of the allocation Chunk. Prev_Chunk is the preceding
   --  chunk of Chunk. Byte indicates the first free byte within Chunk. Addr
   --  denotes the address of the first byte of the allocation. This routine
   --  updates the state of Stack.all to reflect the side effects of the
   --  allocation.

   procedure Allocate_Static
     (Stack : SS_Stack_Ptr; Mem_Size : Memory_Size; Addr : out Address);
   pragma Inline (Allocate_Static);
   --  Allocate enough space on static secondary stack Stack to fit a request
   --  of size Mem_Size. Addr denotes the address of the first byte of the
   --  allocation.

   function Has_Enough_Free_Memory
     (Chunk : SS_Chunk_Ptr; Byte : Memory_Index; Mem_Size : Memory_Size)
      return Boolean;
   pragma Inline (Has_Enough_Free_Memory);
   --  Determine whether chunk Chunk has enough room to fit a memory request of
   --  size Mem_Size, starting from the first free byte of the chunk denoted by
   --  Byte.

   function Number_Of_Chunks (Stack : SS_Stack_Ptr) return Chunk_Count;
   pragma Inline (Number_Of_Chunks);
   --  Count the number of static and dynamic chunks of secondary stack Stack

   function Size_Up_To_And_Including (Chunk : SS_Chunk_Ptr) return Memory_Size;
   pragma Inline (Size_Up_To_And_Including);
   --  Calculate the size of secondary stack which houses chunk Chunk, from the
   --  start of the secondary stack up to and including Chunk itself. The size
   --  includes the following kinds of memory:
   --
   --    * Free memory in used chunks due to alignment holes
   --    * Occupied memory by allocations
   --
   --  This is a constant time operation, regardless of the secondary stack's
   --  nature.

   function Top_Chunk_Id (Stack : SS_Stack_Ptr) return Chunk_Id_With_Invalid;
   pragma Inline (Top_Chunk_Id);
   --  Obtain the Chunk_Id of the chunk indicated by secondary stack Stack's
   --  pointer.

   function Used_Memory_Size (Stack : SS_Stack_Ptr) return Memory_Size;
   pragma Inline (Used_Memory_Size);
   --  Calculate the size of stack Stack's occupied memory usage. This includes
   --  the following kinds of memory:
   --
   --    * Free memory in used chunks due to alignment holes
   --    * Occupied memory by allocations
   --
   --  This is a constant time operation, regardless of the secondary stack's
   --  nature.

   -------------------
   -- Get_Sec_Stack --
   -------------------
   function Get_Sec_Stack return SS_Stack_Ptr is
      kernel_stack_top : Interfaces.Unsigned_32;
      pragma Import
        (Convention    => C, Entity => kernel_stack_top,
         External_Name => "kernel_stack_top");
   begin
      return
        SS_Stack_Ptr
          (SS_Stack_Ptr_Conv.To_Pointer
             (To_Address (Integer_Address (kernel_stack_top))));
   end Get_Sec_Stack;

   -----------------------
   -- Allocate_On_Chunk --
   -----------------------

   procedure Allocate_On_Chunk
     (Stack : SS_Stack_Ptr; Prev_Chunk : SS_Chunk_Ptr; Chunk : SS_Chunk_Ptr;
      Byte  : Memory_Index; Mem_Size : Memory_Size; Addr : out Address)
   is
      New_High_Water_Mark : Memory_Size;

   begin
      --  The allocation occurs on a reused or a brand new chunk. Such a chunk
      --  must always be connected to some previous chunk.

      if Prev_Chunk /= null then
         pragma Assert (Prev_Chunk.Next = Chunk);

         --  Update the Size_Up_To_Chunk because this value is invalidated for
         --  reused and new chunks.
         --
         --                         Prev_Chunk          Chunk
         --                             v                 v
         --    . . . . . . .     +--------------+     +--------
         --                . --> |##############| --> |
         --    . . . . . . .     +--------------+     +--------
         --                       |            |
         --    -------------------+------------+
         --      Size_Up_To_Chunk      Size
         --
         --  The Size_Up_To_Chunk is equal to the size of the whole stack up to
         --  the previous chunk, plus the size of the previous chunk itself.

         Chunk.Size_Up_To_Chunk := Size_Up_To_And_Including (Prev_Chunk);
      end if;

      --  The chunk must have enough room to fit the memory request. If this is
      --  not the case, then a previous step picked the wrong chunk.

      pragma Assert (Has_Enough_Free_Memory (Chunk, Byte, Mem_Size));

      --  The first byte of the allocation is the first free byte within the
      --  chunk.

      Addr := Chunk.Memory (Byte)'Address;

      --  The chunk becomes the chunk indicated by the stack pointer. This is
      --  either the currently indicated chunk, an existing chunk, or a brand
      --  new chunk.

      Stack.Top.Chunk := Chunk;

      --  The next free byte is immediately after the memory request
      --
      --          Addr     Top.Byte
      --          |        |
      --    +-----|--------|----+
      --    |##############|    |
      --    +-------------------+

      --  ??? this calculation may overflow on 32bit targets

      Stack.Top.Byte := Byte + Mem_Size;

      --  At this point the next free byte cannot go beyond the memory capacity
      --  of the chunk indicated by the stack pointer, except when the chunk is
      --  full, in which case it indicates the byte beyond the chunk. Ensure
      --  that the occupied memory is at most as much as the capacity of the
      --  chunk. Top.Byte - 1 denotes the last occupied byte.

      pragma Assert (Stack.Top.Byte - 1 <= Stack.Top.Chunk.Size);

      --  Calculate the new high water mark now that the memory request has
      --  been fulfilled, and update if necessary. The new high water mark is
      --  technically the size of the used memory by the whole stack.

      New_High_Water_Mark := Used_Memory_Size (Stack);

      if New_High_Water_Mark > Stack.High_Water_Mark then
         Stack.High_Water_Mark := New_High_Water_Mark;
      end if;
   end Allocate_On_Chunk;

   ---------------------
   -- Allocate_Static --
   ---------------------

   procedure Allocate_Static
     (Stack : SS_Stack_Ptr; Mem_Size : Memory_Size; Addr : out Address)
   is
   begin
      --  Static secondary stack allocations are performed only on the static
      --  chunk. There should be no dynamic chunks following the static chunk.

      pragma Assert (Stack.Top.Chunk = Stack.Static_Chunk'Access);
      pragma Assert (Stack.Top.Chunk.Next = null);

      --  Raise Storage_Error if the static chunk does not have enough room to
      --  fit the memory request. This indicates that the stack is about to be
      --  depleted.

      --  if not Has_Enough_Free_Memory
      --      (Chunk    => Stack.Top.Chunk, Byte => Stack.Top.Byte,
      --       Mem_Size => Mem_Size)
      --  then
      --  end if;

      Allocate_On_Chunk
        (Stack => Stack, Prev_Chunk => null, Chunk => Stack.Top.Chunk,
         Byte  => Stack.Top.Byte, Mem_Size => Mem_Size, Addr => Addr);
   end Allocate_Static;

   --------------------
   -- Get_Chunk_Info --
   --------------------

   function Get_Chunk_Info
     (Stack : SS_Stack_Ptr; C_Id : Chunk_Id) return Chunk_Info
   is
      function Find_Chunk return SS_Chunk_Ptr;
      pragma Inline (Find_Chunk);
      --  Find the chunk which corresponds to Id. Return null if no such chunk
      --  exists.

      ----------------
      -- Find_Chunk --
      ----------------

      function Find_Chunk return SS_Chunk_Ptr is
         Chunk : SS_Chunk_Ptr;
         Id    : Chunk_Id;

      begin
         Chunk := Stack.Static_Chunk'Access;
         Id    := 1;
         while Chunk /= null loop
            if Id = C_Id then
               return Chunk;
            end if;

            Chunk := Chunk.Next;
            Id    := Id + 1;
         end loop;

         return null;
      end Find_Chunk;

      --  Local variables

      Chunk : constant SS_Chunk_Ptr := Find_Chunk;

      --  Start of processing for Get_Chunk_Info

   begin
      if Chunk = null then
         return Invalid_Chunk;

      else
         return
           (Size => Chunk.Size, Size_Up_To_Chunk => Chunk.Size_Up_To_Chunk);
      end if;
   end Get_Chunk_Info;

   --------------------
   -- Get_Stack_Info --
   --------------------

   function Get_Stack_Info (Stack : SS_Stack_Ptr) return Stack_Info is
      Info : Stack_Info;

   begin
      Info.Default_Chunk_Size := Stack.Default_Chunk_Size;
      Info.Freeable           := Stack.Freeable;
      Info.High_Water_Mark    := Stack.High_Water_Mark;
      Info.Number_Of_Chunks   := Number_Of_Chunks (Stack);
      Info.Top.Byte           := Stack.Top.Byte;
      Info.Top.Chunk          := Top_Chunk_Id (Stack);

      return Info;
   end Get_Stack_Info;

   ----------------------------
   -- Has_Enough_Free_Memory --
   ----------------------------

   function Has_Enough_Free_Memory
     (Chunk : SS_Chunk_Ptr; Byte : Memory_Index; Mem_Size : Memory_Size)
      return Boolean
   is
   begin
      --  Byte - 1 denotes the last occupied byte. Subtracting that byte from
      --  the memory capacity of the chunk yields the size of the free memory
      --  within the chunk. The chunk can fit the request as long as the free
      --  memory is as big as the request.

      return Chunk.Size - (Byte - 1) >= Mem_Size;
   end Has_Enough_Free_Memory;

   ----------------------
   -- Number_Of_Chunks --
   ----------------------

   function Number_Of_Chunks (Stack : SS_Stack_Ptr) return Chunk_Count is
      Chunk : SS_Chunk_Ptr;
      Count : Chunk_Count;

   begin
      Chunk := Stack.Static_Chunk'Access;
      Count := 0;
      while Chunk /= null loop
         Chunk := Chunk.Next;
         Count := Count + 1;
      end loop;

      return Count;
   end Number_Of_Chunks;

   ------------------------------
   -- Size_Up_To_And_Including --
   ------------------------------

   function Size_Up_To_And_Including (Chunk : SS_Chunk_Ptr) return Memory_Size
   is
   begin
      return Chunk.Size_Up_To_Chunk + Chunk.Size;
   end Size_Up_To_And_Including;

   -----------------
   -- SS_Allocate --
   -----------------

   procedure SS_Allocate (Addr : out Address; Storage_Size : Storage_Count) is
      function Round_Up (Size : Storage_Count) return Memory_Size;
      pragma Inline (Round_Up);
      --  Round Size up to the nearest multiple of the maximum alignment

      --------------
      -- Round_Up --
      --------------

      function Round_Up (Size : Storage_Count) return Memory_Size is
         Algn_MS : constant Memory_Size := Standard'Maximum_Alignment;
         Size_MS : constant Memory_Size := Memory_Size (Size);

      begin
         --  Detect a case where the Storage_Size is very large and may yield
         --  a rounded result which is outside the range of Chunk_Memory_Size.
         --  Treat this case as secondary-stack depletion.

         --  if Memory_Size'Last - Algn_MS < Size_MS then
         --     raise Storage_Error with "secondary stack exhaused";
         --  end if;

         return ((Size_MS + Algn_MS - 1) / Algn_MS) * Algn_MS;
      end Round_Up;

      --  Local variables

      Stack    : constant SS_Stack_Ptr := Get_Sec_Stack;
      Mem_Size : Memory_Size;

      --  Start of processing for SS_Allocate

   begin
      --  It should not be possible to request an allocation of negative or
      --  zero size.

      pragma Assert (Storage_Size > 0);

      --  Round the requested size up to the nearest multiple of the maximum
      --  alignment to ensure efficient access.

      Mem_Size := Round_Up (Storage_Size);

      if not Sec_Stack_Dynamic then
         Allocate_Static (Stack, Mem_Size, Addr);
      end if;
   end SS_Allocate;

   -------------
   -- SS_Free --
   -------------

   procedure SS_Free (Stack : in out SS_Stack_Ptr) is null;

   ----------------
   -- SS_Get_Max --
   ----------------

   function SS_Get_Max return Long_Long_Integer is
      Stack : constant SS_Stack_Ptr := Get_Sec_Stack;

   begin
      return Long_Long_Integer (Stack.High_Water_Mark);
   end SS_Get_Max;

   -------------
   -- SS_Info --
   -------------

   procedure SS_Info is
      procedure SS_Info_Dynamic (Stack : SS_Stack_Ptr);
      pragma Inline (SS_Info_Dynamic);
      --  Output relevant information concerning dynamic secondary stack Stack

      function Total_Memory_Size (Stack : SS_Stack_Ptr) return Memory_Size;
      pragma Inline (Total_Memory_Size);
      --  Calculate the size of stack Stack's total memory usage. This includes
      --  the following kinds of memory:
      --
      --    * Free memory in used chunks due to alignment holes
      --    * Free memory in the topmost chunk due to partial usage
      --    * Free memory in unused chunks following the chunk indicated by the
      --      stack pointer.
      --    * Memory occupied by allocations
      --
      --  This is a linear-time operation on the number of chunks.

      ---------------------
      -- SS_Info_Dynamic --
      ---------------------

      procedure SS_Info_Dynamic (Stack : SS_Stack_Ptr) is
      begin
         Put_Line
           ("  Number of Chunks        : " & Number_Of_Chunks (Stack)'Img);

         Put_Line
           ("  Default size of Chunks  : " & Stack.Default_Chunk_Size'Img);
      end SS_Info_Dynamic;

      -----------------------
      -- Total_Memory_Size --
      -----------------------

      function Total_Memory_Size (Stack : SS_Stack_Ptr) return Memory_Size is
         Chunk : SS_Chunk_Ptr;
         Total : Memory_Size;

      begin
         --  The total size of the stack is equal to the size of the stack up
         --  to the chunk indicated by the stack pointer, plus the size of the
         --  indicated chunk, plus the size of any subsequent chunks.

         Total := Size_Up_To_And_Including (Stack.Top.Chunk);

         Chunk := Stack.Top.Chunk.Next;
         while Chunk /= null loop
            Total := Total + Chunk.Size;
            Chunk := Chunk.Next;
         end loop;

         return Total;
      end Total_Memory_Size;

      --  Local variables

      Stack : constant SS_Stack_Ptr := Get_Sec_Stack;

      --  Start of processing for SS_Info

   begin
      Put_Line ("Secondary Stack information:");

      Put_Line
        ("  Total size              : " & Total_Memory_Size (Stack)'Img &
         " bytes");

      Put_Line
        ("  Current allocated space : " & Used_Memory_Size (Stack)'Img &
         " bytes");

      if Sec_Stack_Dynamic then
         SS_Info_Dynamic (Stack);
      end if;
   end SS_Info;

   -------------
   -- SS_Init --
   -------------

   procedure SS_Init
     (Stack : in out SS_Stack_Ptr; Size : Size_Type := Unspecified_Size)
   is
      known_stack : constant SS_Stack_Ptr := Get_Sec_Stack;
   begin
      if Size = Unspecified_Size then
         Stack := known_stack;
      end if;

   end SS_Init;

   -------------
   -- SS_Mark --
   -------------

   function SS_Mark return Mark_Id is
      Stack : constant SS_Stack_Ptr := Get_Sec_Stack;

   begin
      return (Stack => Stack, Top => Stack.Top);
   end SS_Mark;

   ----------------
   -- SS_Release --
   ----------------

   procedure SS_Release (M : Mark_Id) is
   begin
      M.Stack.Top := M.Top;
   end SS_Release;

   ------------------
   -- Top_Chunk_Id --
   ------------------

   function Top_Chunk_Id (Stack : SS_Stack_Ptr) return Chunk_Id_With_Invalid is
      Chunk : SS_Chunk_Ptr;
      Id    : Chunk_Id;

   begin
      Chunk := Stack.Static_Chunk'Access;
      Id    := 1;
      while Chunk /= null loop
         if Chunk = Stack.Top.Chunk then
            return Id;
         end if;

         Chunk := Chunk.Next;
         Id    := Id + 1;
      end loop;

      return Invalid_Chunk_Id;
   end Top_Chunk_Id;

   ----------------------
   -- Used_Memory_Size --
   ----------------------

   function Used_Memory_Size (Stack : SS_Stack_Ptr) return Memory_Size is
   begin
      --  The size of the occupied memory is equal to the size up to the chunk
      --  indicated by the stack pointer, plus the size in use by the indicated
      --  chunk itself. Top.Byte - 1 is the last occupied byte.
      --
      --                                     Top.Byte
      --                                     |
      --    . . . . . . .     +--------------|----+
      --                . ..> |##############|    |
      --    . . . . . . .     +-------------------+
      --                       |             |
      --    -------------------+-------------+
      --      Size_Up_To_Chunk   size in use

      --  ??? this calculation may overflow on 32bit targets

      return Stack.Top.Chunk.Size_Up_To_Chunk + Stack.Top.Byte - 1;
   end Used_Memory_Size;

end System.Secondary_Stack;
