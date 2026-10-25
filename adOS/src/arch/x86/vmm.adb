with Util;
with Loggers;
with x86.pmm; use x86.pmm;
with x86.vmm.vab; use x86.vmm.vab;


package body vmm is
   package Logger renames Loggers;
   function To_Hex is new Util.To_Hex (Virtual_Address);


   function Find_Next_Space
     (CR3 : CR3_register; Size : Storage_Count; Start : Virtual_Address) return Virtual_Address
   is
      Current_Address : Virtual_Address := Start;
      Available_Space : Storage_Count := 0;
      Used_Space      : Storage_Count := 0;
   begin
      if Current_Address = Virtual_Address'First then
         Current_Address := Current_Address + PAGE_SIZE;
      end if;

      while True loop
         Available_Space := Get_Free_Size (CR3, Current_Address);
         exit when Size <= Available_Space;
         Current_Address := Current_Address + Available_Space;
         exit when Is_Last_Address (CR3, Current_Address);
         Used_Space := Get_Allocated_Size (CR3, Current_Address);
         Current_Address := Current_Address + Used_Space;
         exit when Is_Last_Address (CR3, Current_Address);
      end loop;

      if Is_Last_Address (CR3, Current_Address) then
         return Virtual_Address'First;
      end if;

      return Current_Address;
   end;

   function Can_Fit
     (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count) return Boolean
   is
      Page_Offset     : Storage_Offset    := Get_Offset (CR3, Address);
      Aligned_Address : Virtual_Address := Address  - Page_Offset;
      Aligned_Size    : Storage_Count   := Size + Page_Offset;
   begin
      return Aligned_Size <= Get_Free_Size (CR3, Aligned_Address);
   end Can_Fit;

   -- Todo: use aligned adress here
   function Is_Range_Mapped (CR3 : CR3_Register; Address : Virtual_Address; Size : Storage_Count) return Boolean
   is
   begin
      return Size <= Get_Allocated_Size (CR3, Address);
   end Is_Range_Mapped;



   function Alloc_In_Range
     (CR3         : CR3_register;
      Size        : Storage_Count;
      Range_Start, Range_End : Virtual_Address;
      Is_Writable : Boolean := False;
      Is_Usermode : Boolean := False) return Virtual_Address
   is
      Paging_Currently_Enabled : constant Boolean := Is_Paging_Enabled;
      Result : Virtual_Address := Virtual_Address'First;
      Success : Boolean := True;

   begin
      Logger.Log_Debug ("Alloc_In_Range: Allocating" & Size'Image & " bytes");
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      Result := Find_Next_Space (CR3, Size, Range_Start);
      if Result = Virtual_Address'First or else
         Result + Size > Range_End
      then
         Logger.Log_Error ("No more free space in the Page Directory");
         Success := False;
      end if;

      Logger.Log_Debug ("  at " &  To_Hex (Result));

      if Success and then not Alloc
               (CR3,
                Result,
                Size,
                Is_Writable => Is_Writable,
                Is_Usermode => Is_Usermode)
      then
         Success := False;
      end if;

      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;

      if Success then
         Logger.Log_Ok ("  Allocation successfull");
         return Result;
      end if; 

      Logger.Log_Error ("  Allocation failed");

      return Virtual_Address'First;
   end Alloc_In_Range;

   procedure Memory_Unmap
     (CR3 : CR3_register; Address : Virtual_Address; Size : Storage_Count; Free_Page : Boolean)
   is
      Paging_Currently_Enabled : constant Boolean := Is_Paging_Enabled;
   
      Address_Breakdown : Virtual_Address_Break := To_Virtual_Address_Break (Address);
      Page_Count        : constant Positive := Get_Number_Of_Pages (size, Address_Breakdown.Offset);
   
   begin
      if Paging_Currently_Enabled then
         Disable_Paging;
      end if;

      -- Todo change algorithm
      for i in 1 .. Page_Count loop
         Unmap_Page (CR3, From_Virtual_Address_Break (Address_Breakdown), Free_Page);
         Next (Address_Breakdown);
      end loop;
   
      if Paging_Currently_Enabled then
         Enable_Paging;
      end if;
   end Memory_Unmap;

   function Process_To_Process_Map
     (Source_CR3     : CR3_register;
      Source_Address : Virtual_Address;
      Dest_CR3       : CR3_register;
      Size           : Storage_Count;
      Hint           : Virtual_Address := Virtual_Address'First) return Virtual_Address
   is
      Paging_Currently_Enabled : constant Boolean := Is_Paging_Enabled;
      Offset_In_Page          : constant Virtual_Address_Offset := To_Virtual_Address_Break (Source_Address).Offset;
      Page_Count              : constant Positive := Get_Number_Of_Pages (Size, Offset_In_Page);
      Aligned_Source_Address   : constant Virtual_Address := Source_Address - Offset_In_Page;

      Return_Address        : Virtual_Address;
      Dest_Address          : Virtual_Address_Break;

      --------------------------
      -- Compute_Dest_Address --
      --------------------------
      function Compute_Dest_Address return Virtual_Address_Break is
         begin
         if Hint /= Virtual_Address'First then
            return  To_Virtual_Address_Break (Hint);
         else
           return To_Virtual_Address_Break (Find_Next_Space (Dest_CR3, Size + Storage_Count (Offset_In_Page), Virtual_Address'First));
         end if;
      end Compute_Dest_Address;

      ------------------------------
      -- Disable_Paging_If_Needed --
      ------------------------------
      procedure Disable_Paging_If_Needed is
      begin
         if Paging_Currently_Enabled then
            Disable_Paging;
         end if;
      end Disable_Paging_If_Needed;

      ------------------------------
      -- Re_Enable_Paging_If_Needed --
      ------------------------------
      procedure Re_Enable_Paging_If_Needed is
      begin
         if Paging_Currently_Enabled then
            Enable_Paging;
         end if;
      end Re_Enable_Paging_If_Needed;


   begin
      Disable_Paging_If_Needed;

      if not Is_Range_Mapped (Source_CR3, Aligned_Source_Address, Size) then
         Logger.Log_Error ("Process_To_Process_Map: Address is not mapped " & To_Hex (Aligned_Source_Address) & " - " & To_Hex (Aligned_Source_Address + Size));
         Re_Enable_Paging_If_Needed;
         return Virtual_Address'First;
      end if;

      Dest_Address := Compute_Dest_Address;
      if Dest_Address = Null_Address_Break or else not Can_Fit (Dest_CR3, From_Virtual_Address_Break (Dest_Address), Size) then
         Logger.Log_Error ("Map_Process_Memory: Could not find space in destination process");
         Re_Enable_Paging_If_Needed;
         return Virtual_Address'First;
      end if;
      
      Return_Address := From_Virtual_Address_Break (Dest_Address) + Offset_In_Page;
      for i in 0 .. Page_Count - 1 loop
         Map_Physical_Page (
            Process => Dest_CR3,
            Destination => From_Virtual_Address_Break (Dest_Address),
            Address_To_Map => Virtual_To_Physical_Address (Source_CR3, Aligned_Source_Address + Storage_Count (i * Positive (PMM_PAGE_SIZE))),
            Is_Writable => True,
            Is_Usermode => True);
         Next (Dest_Address);
      end loop;

      Re_Enable_Paging_If_Needed;
      return Return_Address;
   end Process_To_Process_Map;
   



   ---------------------------
   -- Enable_Kernel_Mapping --
   ---------------------------
   procedure Enable_Kernel_Mapping is
   begin
      Disable_Paging;
      Load_CR3 (Kernel_CR3);
      Enable_Paging;
   end Enable_Kernel_Mapping;

   function Get_Kernel_CR3 return CR3_register is (Kernel_CR3);
   function Get_Process_CR3 return CR3_register is (Process_CR3);

   procedure Set_Kernel_CR3 (CR3 : CR3_register) is
   begin
      Kernel_CR3 := CR3;
   end Set_Kernel_CR3;

   procedure Set_Process_CR3 (CR3 : CR3_register) is
   begin
      Process_CR3 := CR3;
   end Set_Process_CR3;
end vmm;