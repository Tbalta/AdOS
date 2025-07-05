------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                       A D A . E X C E P T I O N S                        --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--          Copyright (C) 1992-2023, Free Software Foundation, Inc.         --
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

pragma Style_Checks (All_Checks);
--  No subprogram ordering check, due to logical grouping

with System;                  use System;

--  with System.Exceptions;       use System.Exceptions;
--  with System.Exceptions_Debug; use System.Exceptions_Debug;
with System.Standard_Library; use System.Standard_Library;
--  with System.Soft_Links;       use System.Soft_Links;
--  with System.WCh_Con;          use System.WCh_Con;
--  with System.WCh_StW;          use System.WCh_StW;

pragma Warnings (Off);
--  Suppress complaints about Symbolic not being referenced, and about it not
--  having pragma Preelaborate.
--  with System.Traceback.Symbolic;
--  Bring Symbolic into the closure. If it is the s-trasym-dwarf.adb version,
--  it will install symbolic tracebacks as the default decorator. Otherwise,
--  symbolic tracebacks are not supported, and we fall back to hexadecimal
--  addresses.
pragma Warnings (On);

package body Ada.Exceptions is

   pragma Suppress (All_Checks);
   --  We definitely do not want exceptions occurring within this unit, or
   --  we are in big trouble. If an exceptional situation does occur, better
   --  that it not be raised, since raising it can cause confusing chaos.

   function Image (Index : Integer) return String;
   --  Return string image corresponding to Index

   --  Create and build an exception occurrence using exception id E and
   --  nul-terminated message M. Return the machine occurrence.

   procedure Raise_Exception_No_Defer
     (E : Exception_Id; Message : String := "");
   pragma Export
     (Ada, Raise_Exception_No_Defer,
      "ada__exceptions__raise_exception_no_defer");
   pragma No_Return (Raise_Exception_No_Defer);
   --  Similar to Raise_Exception, but with no abort deferral

   procedure Raise_With_Msg (E : Exception_Id);
   pragma No_Return (Raise_With_Msg);
   pragma Export (C, Raise_With_Msg, "__gnat_raise_with_msg");
   --  Raises an exception with given exception id value. A message
   --  is associated with the raise, and has already been stored in the
   --  exception occurrence referenced by the Current_Excep in the TSD.
   --  Abort is deferred before the raise call.

   procedure Raise_With_Location_And_Msg
     (E : Exception_Id; F : System.Address; L : Integer; C : Integer := 0;
      M : System.Address := System.Null_Address);
   pragma No_Return (Raise_With_Location_And_Msg);
   --  Raise an exception with given exception id value. A filename and line
   --  number is associated with the raise and is stored in the exception
   --  occurrence and in addition a column and a string message M may be
   --  appended to this (if not null/0).

   procedure Raise_Constraint_Error (File : System.Address; Line : Integer);
   pragma No_Return (Raise_Constraint_Error);
   pragma Export (C, Raise_Constraint_Error, "__gnat_raise_constraint_error");
   --  Raise constraint error with file:line information

   procedure Raise_Constraint_Error_Msg
     (File : System.Address; Line : Integer; Column : Integer;
      Msg  : System.Address);
   pragma No_Return (Raise_Constraint_Error_Msg);
   pragma Export
     (C, Raise_Constraint_Error_Msg, "__gnat_raise_constraint_error_msg");
   --  Raise constraint error with file:line:col + msg information

   procedure Raise_Program_Error (File : System.Address; Line : Integer);
   pragma No_Return (Raise_Program_Error);
   pragma Export (C, Raise_Program_Error, "__gnat_raise_program_error");
   --  Raise program error with file:line information

   procedure Raise_Program_Error_Msg
     (File : System.Address; Line : Integer; Msg : System.Address);
   pragma No_Return (Raise_Program_Error_Msg);
   pragma Export
     (C, Raise_Program_Error_Msg, "__gnat_raise_program_error_msg");
   --  Raise program error with file:line + msg information

   procedure Raise_Storage_Error (File : System.Address; Line : Integer);
   pragma No_Return (Raise_Storage_Error);
   pragma Export (C, Raise_Storage_Error, "__gnat_raise_storage_error");
   --  Raise storage error with file:line information

   procedure Raise_Storage_Error_Msg
     (File : System.Address; Line : Integer; Msg : System.Address);
   pragma No_Return (Raise_Storage_Error_Msg);
   pragma Export
     (C, Raise_Storage_Error_Msg, "__gnat_raise_storage_error_msg");
   --  Raise storage error with file:line + reason msg information

   --  The exception raising process and the automatic tracing mechanism rely
   --  on some careful use of flags attached to the exception occurrence. The
   --  graph below illustrates the relations between the Raise_ subprograms
   --  and identifies the points where basic flags such as Exception_Raised
   --  are initialized.

   --  (i) signs indicate the flags initialization points. R stands for Raise,
   --  W for With, and E for Exception.

   --                   R_No_Msg    R_E   R_Pe  R_Ce  R_Se
   --                       |        |     |     |     |
   --                       +--+  +--+     +---+ | +---+
   --                          |  |            | | |
   --     R_E_No_Defer(i)    R_W_Msg(i)       R_W_Loc
   --           |               |              |   |
   --           +------------+  |  +-----------+   +--+
   --                        |  |  |                  |
   --                        |  |  |             Set_E_C_Msg(i)
   --                        |  |  |
   --            Complete_And_Propagate_Occurrence

   procedure Reraise;
   pragma No_Return (Reraise);
   pragma Export (C, Reraise, "__gnat_reraise");
   --  Reraises the exception referenced by the Current_Excep field
   --  of the TSD (all fields of this exception occurrence are set).
   --  Abort is deferred before the reraise operation. Called from
   --  System.Tasking.RendezVous.Exceptional_Complete_RendezVous

   --  Called from s-tasren.adb:Local_Complete_RendezVous and
   --  s-tpobop.adb:Exceptional_Complete_Entry_Body to setup Target from
   --  Source as an exception to be propagated in the caller task. Target is
   --  expected to be a pointer to the fixed TSD occurrence for this task.

   --------------------------------
   -- Run-Time Check Subprograms --
   --------------------------------

   --  These subprograms raise a specific exception with a reason message
   --  attached. The parameters are the file name and line number in each
   --  case. The names are defined by Exp_Ch11.Get_RT_Exception_Name.

   procedure Rcheck_CE_Access_Check (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Null_Access_Parameter
     (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Discriminant_Check
     (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Divide_By_Zero (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Explicit_Raise (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Index_Check (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Invalid_Data (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Length_Check (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Null_Exception_Id
     (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Null_Not_Allowed
     (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Overflow_Check (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Partition_Check (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Range_Check (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Tag_Check (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Access_Before_Elaboration
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Accessibility_Check
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Address_Of_Intrinsic
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Aliased_Parameters
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_All_Guards_Closed
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Bad_Predicated_Generic_Type
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Build_In_Place_Mismatch
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Current_Task_In_Entry_Body
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Duplicated_Entry_Address
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Explicit_Raise (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Implicit_Return (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Misaligned_Address_Value
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Missing_Return (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Non_Transportable_Actual
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Overlaid_Controlled_Object
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Potentially_Blocking_Operation
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Stubbed_Subprogram_Called
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Unchecked_Union_Restriction
     (File : System.Address; Line : Integer);
   procedure Rcheck_SE_Empty_Storage_Pool
     (File : System.Address; Line : Integer);
   procedure Rcheck_SE_Explicit_Raise (File : System.Address; Line : Integer);
   procedure Rcheck_SE_Infinite_Recursion
     (File : System.Address; Line : Integer);
   procedure Rcheck_SE_Object_Too_Large
     (File : System.Address; Line : Integer);
   procedure Rcheck_PE_Stream_Operation_Not_Allowed
     (File : System.Address; Line : Integer);
   procedure Rcheck_CE_Access_Check_Ext
     (File : System.Address; Line, Column : Integer);
   procedure Rcheck_CE_Index_Check_Ext
     (File : System.Address; Line, Column, Index, First, Last : Integer);
   procedure Rcheck_CE_Invalid_Data_Ext
     (File : System.Address; Line, Column, Index, First, Last : Integer);
   procedure Rcheck_CE_Range_Check_Ext
     (File : System.Address; Line, Column, Index, First, Last : Integer);

   procedure Rcheck_PE_Finalize_Raised_Exception
     (File : System.Address; Line : Integer);
   --  This routine is separated out because it has quite different behavior
   --  from the others. This is the "finalize/adjust raised exception". This
   --  subprogram is always called with abort deferred, unlike all other
   --  Rcheck_* subprograms, it needs to call Raise_Exception_No_Defer.

   pragma Export (C, Rcheck_CE_Access_Check, "__gnat_rcheck_CE_Access_Check");
   pragma Export
     (C, Rcheck_CE_Null_Access_Parameter,
      "__gnat_rcheck_CE_Null_Access_Parameter");
   pragma Export
     (C, Rcheck_CE_Discriminant_Check, "__gnat_rcheck_CE_Discriminant_Check");
   pragma Export
     (C, Rcheck_CE_Divide_By_Zero, "__gnat_rcheck_CE_Divide_By_Zero");
   pragma Export
     (C, Rcheck_CE_Explicit_Raise, "__gnat_rcheck_CE_Explicit_Raise");
   pragma Export (C, Rcheck_CE_Index_Check, "__gnat_rcheck_CE_Index_Check");
   pragma Export (C, Rcheck_CE_Invalid_Data, "__gnat_rcheck_CE_Invalid_Data");
   pragma Export (C, Rcheck_CE_Length_Check, "__gnat_rcheck_CE_Length_Check");
   pragma Export
     (C, Rcheck_CE_Null_Exception_Id, "__gnat_rcheck_CE_Null_Exception_Id");
   pragma Export
     (C, Rcheck_CE_Null_Not_Allowed, "__gnat_rcheck_CE_Null_Not_Allowed");
   pragma Export
     (C, Rcheck_CE_Overflow_Check, "__gnat_rcheck_CE_Overflow_Check");
   pragma Export
     (C, Rcheck_CE_Partition_Check, "__gnat_rcheck_CE_Partition_Check");
   pragma Export (C, Rcheck_CE_Range_Check, "__gnat_rcheck_CE_Range_Check");
   pragma Export (C, Rcheck_CE_Tag_Check, "__gnat_rcheck_CE_Tag_Check");
   pragma Export
     (C, Rcheck_PE_Access_Before_Elaboration,
      "__gnat_rcheck_PE_Access_Before_Elaboration");
   pragma Export
     (C, Rcheck_PE_Accessibility_Check,
      "__gnat_rcheck_PE_Accessibility_Check");
   pragma Export
     (C, Rcheck_PE_Address_Of_Intrinsic,
      "__gnat_rcheck_PE_Address_Of_Intrinsic");
   pragma Export
     (C, Rcheck_PE_Aliased_Parameters, "__gnat_rcheck_PE_Aliased_Parameters");
   pragma Export
     (C, Rcheck_PE_All_Guards_Closed, "__gnat_rcheck_PE_All_Guards_Closed");
   pragma Export
     (C, Rcheck_PE_Bad_Predicated_Generic_Type,
      "__gnat_rcheck_PE_Bad_Predicated_Generic_Type");
   pragma Export
     (C, Rcheck_PE_Build_In_Place_Mismatch,
      "__gnat_rcheck_PE_Build_In_Place_Mismatch");
   pragma Export
     (C, Rcheck_PE_Current_Task_In_Entry_Body,
      "__gnat_rcheck_PE_Current_Task_In_Entry_Body");
   pragma Export
     (C, Rcheck_PE_Duplicated_Entry_Address,
      "__gnat_rcheck_PE_Duplicated_Entry_Address");
   pragma Export
     (C, Rcheck_PE_Explicit_Raise, "__gnat_rcheck_PE_Explicit_Raise");
   pragma Export
     (C, Rcheck_PE_Finalize_Raised_Exception,
      "__gnat_rcheck_PE_Finalize_Raised_Exception");
   pragma Export
     (C, Rcheck_PE_Implicit_Return, "__gnat_rcheck_PE_Implicit_Return");
   pragma Export
     (C, Rcheck_PE_Misaligned_Address_Value,
      "__gnat_rcheck_PE_Misaligned_Address_Value");
   pragma Export
     (C, Rcheck_PE_Missing_Return, "__gnat_rcheck_PE_Missing_Return");
   pragma Export
     (C, Rcheck_PE_Non_Transportable_Actual,
      "__gnat_rcheck_PE_Non_Transportable_Actual");
   pragma Export
     (C, Rcheck_PE_Overlaid_Controlled_Object,
      "__gnat_rcheck_PE_Overlaid_Controlled_Object");
   pragma Export
     (C, Rcheck_PE_Potentially_Blocking_Operation,
      "__gnat_rcheck_PE_Potentially_Blocking_Operation");
   pragma Export
     (C, Rcheck_PE_Stream_Operation_Not_Allowed,
      "__gnat_rcheck_PE_Stream_Operation_Not_Allowed");
   pragma Export
     (C, Rcheck_PE_Stubbed_Subprogram_Called,
      "__gnat_rcheck_PE_Stubbed_Subprogram_Called");
   pragma Export
     (C, Rcheck_PE_Unchecked_Union_Restriction,
      "__gnat_rcheck_PE_Unchecked_Union_Restriction");
   pragma Export
     (C, Rcheck_SE_Empty_Storage_Pool, "__gnat_rcheck_SE_Empty_Storage_Pool");
   pragma Export
     (C, Rcheck_SE_Explicit_Raise, "__gnat_rcheck_SE_Explicit_Raise");
   pragma Export
     (C, Rcheck_SE_Infinite_Recursion, "__gnat_rcheck_SE_Infinite_Recursion");
   pragma Export
     (C, Rcheck_SE_Object_Too_Large, "__gnat_rcheck_SE_Object_Too_Large");

   pragma Export
     (C, Rcheck_CE_Access_Check_Ext, "__gnat_rcheck_CE_Access_Check_ext");
   pragma Export
     (C, Rcheck_CE_Index_Check_Ext, "__gnat_rcheck_CE_Index_Check_ext");
   pragma Export
     (C, Rcheck_CE_Invalid_Data_Ext, "__gnat_rcheck_CE_Invalid_Data_ext");
   pragma Export
     (C, Rcheck_CE_Range_Check_Ext, "__gnat_rcheck_CE_Range_Check_ext");

   --  None of these procedures ever returns (they raise an exception). By
   --  using pragma No_Return, we ensure that any junk code after the call,
   --  such as normal return epilogue stuff, can be eliminated).

   pragma No_Return (Rcheck_CE_Access_Check);
   pragma No_Return (Rcheck_CE_Null_Access_Parameter);
   pragma No_Return (Rcheck_CE_Discriminant_Check);
   pragma No_Return (Rcheck_CE_Divide_By_Zero);
   pragma No_Return (Rcheck_CE_Explicit_Raise);
   pragma No_Return (Rcheck_CE_Index_Check);
   pragma No_Return (Rcheck_CE_Invalid_Data);
   pragma No_Return (Rcheck_CE_Length_Check);
   pragma No_Return (Rcheck_CE_Null_Exception_Id);
   pragma No_Return (Rcheck_CE_Null_Not_Allowed);
   pragma No_Return (Rcheck_CE_Overflow_Check);
   pragma No_Return (Rcheck_CE_Partition_Check);
   pragma No_Return (Rcheck_CE_Range_Check);
   pragma No_Return (Rcheck_CE_Tag_Check);
   pragma No_Return (Rcheck_PE_Access_Before_Elaboration);
   pragma No_Return (Rcheck_PE_Accessibility_Check);
   pragma No_Return (Rcheck_PE_Address_Of_Intrinsic);
   pragma No_Return (Rcheck_PE_Aliased_Parameters);
   pragma No_Return (Rcheck_PE_All_Guards_Closed);
   pragma No_Return (Rcheck_PE_Bad_Predicated_Generic_Type);
   pragma No_Return (Rcheck_PE_Build_In_Place_Mismatch);
   pragma No_Return (Rcheck_PE_Current_Task_In_Entry_Body);
   pragma No_Return (Rcheck_PE_Duplicated_Entry_Address);
   pragma No_Return (Rcheck_PE_Explicit_Raise);
   pragma No_Return (Rcheck_PE_Implicit_Return);
   pragma No_Return (Rcheck_PE_Misaligned_Address_Value);
   pragma No_Return (Rcheck_PE_Missing_Return);
   pragma No_Return (Rcheck_PE_Non_Transportable_Actual);
   pragma No_Return (Rcheck_PE_Overlaid_Controlled_Object);
   pragma No_Return (Rcheck_PE_Potentially_Blocking_Operation);
   pragma No_Return (Rcheck_PE_Stream_Operation_Not_Allowed);
   pragma No_Return (Rcheck_PE_Stubbed_Subprogram_Called);
   pragma No_Return (Rcheck_PE_Unchecked_Union_Restriction);
   pragma No_Return (Rcheck_PE_Finalize_Raised_Exception);
   pragma No_Return (Rcheck_SE_Empty_Storage_Pool);
   pragma No_Return (Rcheck_SE_Explicit_Raise);
   pragma No_Return (Rcheck_SE_Infinite_Recursion);
   pragma No_Return (Rcheck_SE_Object_Too_Large);

   pragma No_Return (Rcheck_CE_Access_Check_Ext);
   pragma No_Return (Rcheck_CE_Index_Check_Ext);
   pragma No_Return (Rcheck_CE_Invalid_Data_Ext);
   pragma No_Return (Rcheck_CE_Range_Check_Ext);

   --  Make all of these procedures callable from strub contexts.
   --  These attributes are not visible to callers; they are made
   --  visible in trans.c:build_raise_check.

   pragma Machine_Attribute (Rcheck_CE_Access_Check, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_CE_Null_Access_Parameter, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_CE_Discriminant_Check, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Divide_By_Zero, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Explicit_Raise, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Index_Check, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Invalid_Data, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Length_Check, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Null_Exception_Id, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Null_Not_Allowed, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Overflow_Check, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Partition_Check, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Range_Check, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Tag_Check, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Access_Before_Elaboration, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Accessibility_Check, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Address_Of_Intrinsic, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Aliased_Parameters, "strub", "callable");
   pragma Machine_Attribute (Rcheck_PE_All_Guards_Closed, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Bad_Predicated_Generic_Type, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Build_In_Place_Mismatch, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Current_Task_In_Entry_Body, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Duplicated_Entry_Address, "strub", "callable");
   pragma Machine_Attribute (Rcheck_PE_Explicit_Raise, "strub", "callable");
   pragma Machine_Attribute (Rcheck_PE_Implicit_Return, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Misaligned_Address_Value, "strub", "callable");
   pragma Machine_Attribute (Rcheck_PE_Missing_Return, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Non_Transportable_Actual, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Overlaid_Controlled_Object, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Potentially_Blocking_Operation, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Stream_Operation_Not_Allowed, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Stubbed_Subprogram_Called, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Unchecked_Union_Restriction, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_PE_Finalize_Raised_Exception, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_SE_Empty_Storage_Pool, "strub", "callable");
   pragma Machine_Attribute (Rcheck_SE_Explicit_Raise, "strub", "callable");
   pragma Machine_Attribute
     (Rcheck_SE_Infinite_Recursion, "strub", "callable");
   pragma Machine_Attribute (Rcheck_SE_Object_Too_Large, "strub", "callable");

   pragma Machine_Attribute (Rcheck_CE_Access_Check_Ext, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Index_Check_Ext, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Invalid_Data_Ext, "strub", "callable");
   pragma Machine_Attribute (Rcheck_CE_Range_Check_Ext, "strub", "callable");

   ---------------------------------------------
   -- Reason Strings for Run-Time Check Calls --
   ---------------------------------------------

   --  These strings are null-terminated and are used by Rcheck_nn. The
   --  strings correspond to the definitions for Types.RT_Exception_Code.

   use ASCII;

   Rmsg_00 : constant String := "access check failed" & NUL;
   Rmsg_01 : constant String := "access parameter is null" & NUL;
   Rmsg_02 : constant String := "discriminant check failed" & NUL;
   Rmsg_03 : constant String := "divide by zero" & NUL;
   Rmsg_04 : constant String := "explicit raise" & NUL;
   Rmsg_05 : constant String := "index check failed" & NUL;
   Rmsg_06 : constant String := "invalid data" & NUL;
   Rmsg_07 : constant String := "length check failed" & NUL;
   Rmsg_08 : constant String := "null Exception_Id" & NUL;
   Rmsg_09 : constant String := "null-exclusion check failed" & NUL;
   Rmsg_10 : constant String := "overflow check failed" & NUL;
   Rmsg_11 : constant String := "partition check failed" & NUL;
   Rmsg_12 : constant String := "range check failed" & NUL;
   Rmsg_13 : constant String := "tag check failed" & NUL;
   Rmsg_14 : constant String := "access before elaboration" & NUL;
   Rmsg_15 : constant String := "accessibility check failed" & NUL;
   Rmsg_16 : constant String :=
     "attempt to take address of" & " intrinsic subprogram" & NUL;
   Rmsg_17 : constant String := "aliased parameters" & NUL;
   Rmsg_18 : constant String := "all guards closed" & NUL;
   Rmsg_19 : constant String :=
     "improper use of generic subtype" & " with predicate" & NUL;
   Rmsg_20 : constant String :=
     "Current_Task referenced in entry" & " body" & NUL;
   Rmsg_21 : constant String := "duplicated entry address" & NUL;
   Rmsg_22 : constant String := "explicit raise" & NUL;
   Rmsg_24 : constant String := "implicit return with No_Return" & NUL;
   Rmsg_25 : constant String := "misaligned address value" & NUL;
   Rmsg_26 : constant String := "missing return" & NUL;
   Rmsg_27 : constant String := "overlaid controlled object" & NUL;
   Rmsg_28 : constant String := "potentially blocking operation" & NUL;
   Rmsg_29 : constant String := "stubbed subprogram called" & NUL;
   Rmsg_30 : constant String := "unchecked union restriction" & NUL;
   Rmsg_31 : constant String :=
     "actual/returned class-wide" & " value not transportable" & NUL;
   Rmsg_32 : constant String := "empty storage pool" & NUL;
   Rmsg_33 : constant String := "explicit raise" & NUL;
   Rmsg_34 : constant String := "infinite recursion" & NUL;
   Rmsg_35 : constant String := "object too large" & NUL;
   Rmsg_36 : constant String := "stream operation not allowed" & NUL;
   Rmsg_37 : constant String := "build-in-place mismatch" & NUL;

   -----------------------
   -- Polling Interface --
   -----------------------

   type Unsigned is mod 2**32;

   Counter : Unsigned := 0;
   pragma Warnings (Off, Counter);
   --  This counter is provided for convenience. It can be used in Poll to
   --  perform periodic but not systematic operations.

   --  The actual polling routine is separate, so that it can easily be
   --  replaced with a target dependent version.
   -------------------
   -- EId_To_String --
   -------------------

   ------------------
   -- EO_To_String --
   ------------------

   ------------------------
   -- Exception_Identity --
   ------------------------

   function Exception_Identity (X : Exception_Occurrence) return Exception_Id
   is
   begin
      --  Note that the following test used to be here for the original
      --  Ada 95 semantics, but these were modified by AI-241 to require
      --  returning Null_Id instead of raising Constraint_Error.

      if X.Id = Null_Id then
         raise Constraint_Error;
      end if;

      return X.Id;
   end Exception_Identity;

   ---------------------------
   -- Exception_Information --
   ---------------------------

   function Exception_Information (X : Exception_Occurrence) return String is
   begin
      if X.Id = Null_Id then
         raise Constraint_Error;
      else
         return "Exception_Information";
      end if;
   end Exception_Information;

   -----------------------
   -- Exception_Message --
   -----------------------

   function Exception_Message (X : Exception_Occurrence) return String is
   begin
      if X.Id = Null_Id then
         raise Constraint_Error;
      else
         return X.Msg (1 .. X.Msg_Length);
      end if;
   end Exception_Message;

   --------------------
   -- Exception_Name --
   --------------------

   function Exception_Name (Id : Exception_Id) return String is
   begin
      if Id = null then
         raise Constraint_Error;
      else
         return To_Ptr (Id.Full_Name) (1 .. Id.Name_Length - 1);
      end if;
   end Exception_Name;

   function Exception_Name (X : Exception_Occurrence) return String is
   begin
      return Exception_Name (X.Id);
   end Exception_Name;

   ---------------------------
   -- Exception_Name_Simple --
   ---------------------------

   function Exception_Name_Simple (X : Exception_Occurrence) return String is
      Name : constant String := Exception_Name (X);
      P    : Natural;

   begin
      P := Name'Length;
      while P > 1 loop
         exit when Name (P - 1) = '.';
         P := P - 1;
      end loop;

      --  Return result making sure lower bound is 1

      declare
         subtype Rname is String (1 .. Name'Length - P + 1);
      begin
         return Rname (Name (P .. Name'Length));
      end;
   end Exception_Name_Simple;

   function Get_Exception_Machine_Occurrence
     (X : Exception_Occurrence) return System.Address
   is
   begin
      return X.Machine_Occurrence;
   end Get_Exception_Machine_Occurrence;

   -----------
   -- Image --
   -----------

   function Image (Index : Integer) return String is
      Result : constant String := Integer'Image (Index);
   begin
      if Result (1) = ' ' then
         return Result (2 .. Result'Last);
      else
         return Result;
      end if;
   end Image;

   ----------------------------
   -- Raise_Constraint_Error --
   ----------------------------

   procedure Raise_Constraint_Error (File : System.Address; Line : Integer) is
   begin
      Raise_With_Location_And_Msg (Constraint_Error_Def'Access, File, Line);
   end Raise_Constraint_Error;

   --------------------------------
   -- Raise_Constraint_Error_Msg --
   --------------------------------

   procedure Raise_Constraint_Error_Msg
     (File : System.Address; Line : Integer; Column : Integer;
      Msg  : System.Address)
   is
   begin
      Raise_With_Location_And_Msg
        (Constraint_Error_Def'Access, File, Line, Column, Msg);
   end Raise_Constraint_Error_Msg;

   ---------------------
   -- Raise_Exception --
   ---------------------

   procedure Raise_Exception (E : Exception_Id; Message : String := "") is
   begin
      --  Raise CE if E = Null_ID (AI-446)

      --  if E = 0 then
      --     EF := Constraint_Error'Identity;
      --  end if;

      --  Go ahead and raise appropriate exception

      PANIC (Interfaces.C.To_C (Exception_Name (E) & Message));
   end Raise_Exception;

   ----------------------------
   -- Raise_Exception_Always --
   ----------------------------

   procedure Raise_Exception_Always (E : Exception_Id; Message : String := "")
   is
   --  X : constant EOA := Exception_Propagation.Allocate_Occurrence;

   begin
      Raise_Exception (E, Message);
   end Raise_Exception_Always;

   ------------------------------
   -- Raise_Exception_No_Defer --
   ------------------------------

   procedure Raise_Exception_No_Defer
     (E : Exception_Id; Message : String := "")
   is
   --  X : constant EOA := Exception_Propagation.Allocate_Occurrence;

   begin
      Raise_Exception (E, Message);
   end Raise_Exception_No_Defer;

   -------------------------------------
   -- Raise_From_Controlled_Operation --
   -------------------------------------

   procedure Raise_From_Controlled_Operation
     (X : Ada.Exceptions.Exception_Occurrence)
   is
      Prefix             : constant String  := "adjust/finalize raised ";
      Orig_Msg           : constant String  := Exception_Message (X);
      Orig_Prefix_Length : constant Natural :=
        Integer'Min (Prefix'Length, Orig_Msg'Length);

      Orig_Prefix :
        String renames
        Orig_Msg (Orig_Msg'First .. Orig_Msg'First + Orig_Prefix_Length - 1);

   begin
      --  Message already has the proper prefix, just re-raise

      if Orig_Prefix = Prefix then
         Raise_Exception (Program_Error'Identity, Orig_Msg);
      else
         declare
            New_Msg : constant String := Prefix & Exception_Name (X);

         begin
            --  No message present, just provide our own

            if Orig_Msg = "" then
               Raise_Exception (Program_Error'Identity, New_Msg);
               --  Message present, add informational prefix

            else
               Raise_Exception
                 (Program_Error'Identity, New_Msg & " (" & Orig_Msg & ")");
            end if;
         end;
      end if;
   end Raise_From_Controlled_Operation;

   -------------------------
   -- Raise_Program_Error --
   -------------------------

   procedure Raise_Program_Error (File : System.Address; Line : Integer) is
   begin
      Raise_With_Location_And_Msg (Program_Error_Def'Access, File, Line);
   end Raise_Program_Error;

   -----------------------------
   -- Raise_Program_Error_Msg --
   -----------------------------

   procedure Raise_Program_Error_Msg
     (File : System.Address; Line : Integer; Msg : System.Address)
   is
   begin
      Raise_With_Location_And_Msg
        (Program_Error_Def'Access, File, Line, M => Msg);
   end Raise_Program_Error_Msg;

   -------------------------
   -- Raise_Storage_Error --
   -------------------------

   procedure Raise_Storage_Error (File : System.Address; Line : Integer) is
   begin
      Raise_With_Location_And_Msg (Storage_Error_Def'Access, File, Line);
   end Raise_Storage_Error;

   -----------------------------
   -- Raise_Storage_Error_Msg --
   -----------------------------

   procedure Raise_Storage_Error_Msg
     (File : System.Address; Line : Integer; Msg : System.Address)
   is
   begin
      Raise_With_Location_And_Msg
        (Storage_Error_Def'Access, File, Line, M => Msg);
   end Raise_Storage_Error_Msg;

   ---------------------------------
   -- Raise_With_Location_And_Msg --
   ---------------------------------

   procedure Raise_With_Location_And_Msg
     (E : Exception_Id; F : System.Address; L : Integer; C : Integer := 0;
      M : System.Address := System.Null_Address)
   is
   begin
      Raise_Exception (E,  " at" & L'Image & ":" & C'Image);
   end Raise_With_Location_And_Msg;

   --------------------
   -- Raise_With_Msg --
   --------------------

   procedure Raise_With_Msg (E : Exception_Id) is
   --  Excep : constant EOA := Exception_Propagation.Allocate_Occurrence;
   begin
      --  Excep.Exception_Raised := False;
      --  Excep.Id               := E;
      --  Excep.Pid              := Local_Partition_ID;

      --  --  Copy the message from the current exception
      --  --  Change the interface to be called with an occurrence ???

      --  Excep.Msg_Length                  := Ex.Msg_Length;
      --  Excep.Msg (1 .. Excep.Msg_Length) := Ex.Msg (1 .. Ex.Msg_Length);

      --  The following is a common pattern, should be abstracted
      --  into a procedure call ???
      Raise_Exception (E, "Raise_With_Msg");
   end Raise_With_Msg;

   -----------------------------------------
   -- Calls to Run-Time Check Subprograms --
   -----------------------------------------
   procedure Rcheck_CE_Access_Check (File : System.Address; Line : Integer) is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_00'Address);
   end Rcheck_CE_Access_Check;

   procedure Rcheck_CE_Null_Access_Parameter
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_01'Address);
   end Rcheck_CE_Null_Access_Parameter;

   procedure Rcheck_CE_Discriminant_Check
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_02'Address);
   end Rcheck_CE_Discriminant_Check;

   procedure Rcheck_CE_Divide_By_Zero (File : System.Address; Line : Integer)
   is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_03'Address);
   end Rcheck_CE_Divide_By_Zero;

   procedure Rcheck_CE_Explicit_Raise (File : System.Address; Line : Integer)
   is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_04'Address);
   end Rcheck_CE_Explicit_Raise;

   procedure Rcheck_CE_Index_Check (File : System.Address; Line : Integer) is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_05'Address);
   end Rcheck_CE_Index_Check;

   procedure Rcheck_CE_Invalid_Data (File : System.Address; Line : Integer) is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_06'Address);
   end Rcheck_CE_Invalid_Data;

   procedure Rcheck_CE_Length_Check (File : System.Address; Line : Integer) is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_07'Address);
   end Rcheck_CE_Length_Check;

   procedure Rcheck_CE_Null_Exception_Id
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_08'Address);
   end Rcheck_CE_Null_Exception_Id;

   procedure Rcheck_CE_Null_Not_Allowed (File : System.Address; Line : Integer)
   is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_09'Address);
   end Rcheck_CE_Null_Not_Allowed;

   procedure Rcheck_CE_Overflow_Check (File : System.Address; Line : Integer)
   is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_10'Address);
   end Rcheck_CE_Overflow_Check;

   procedure Rcheck_CE_Partition_Check (File : System.Address; Line : Integer)
   is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_11'Address);
   end Rcheck_CE_Partition_Check;

   procedure Rcheck_CE_Range_Check (File : System.Address; Line : Integer) is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_12'Address);
   end Rcheck_CE_Range_Check;

   procedure Rcheck_CE_Tag_Check (File : System.Address; Line : Integer) is
   begin
      Raise_Constraint_Error_Msg (File, Line, 0, Rmsg_13'Address);
   end Rcheck_CE_Tag_Check;

   procedure Rcheck_PE_Access_Before_Elaboration
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_14'Address);
   end Rcheck_PE_Access_Before_Elaboration;

   procedure Rcheck_PE_Accessibility_Check
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_15'Address);
   end Rcheck_PE_Accessibility_Check;

   procedure Rcheck_PE_Address_Of_Intrinsic
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_16'Address);
   end Rcheck_PE_Address_Of_Intrinsic;

   procedure Rcheck_PE_Aliased_Parameters
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_17'Address);
   end Rcheck_PE_Aliased_Parameters;

   procedure Rcheck_PE_All_Guards_Closed
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_18'Address);
   end Rcheck_PE_All_Guards_Closed;

   procedure Rcheck_PE_Bad_Predicated_Generic_Type
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_19'Address);
   end Rcheck_PE_Bad_Predicated_Generic_Type;

   procedure Rcheck_PE_Build_In_Place_Mismatch
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_37'Address);
   end Rcheck_PE_Build_In_Place_Mismatch;

   procedure Rcheck_PE_Current_Task_In_Entry_Body
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_20'Address);
   end Rcheck_PE_Current_Task_In_Entry_Body;

   procedure Rcheck_PE_Duplicated_Entry_Address
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_21'Address);
   end Rcheck_PE_Duplicated_Entry_Address;

   procedure Rcheck_PE_Explicit_Raise (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_22'Address);
   end Rcheck_PE_Explicit_Raise;

   procedure Rcheck_PE_Implicit_Return (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_24'Address);
   end Rcheck_PE_Implicit_Return;

   procedure Rcheck_PE_Misaligned_Address_Value
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_25'Address);
   end Rcheck_PE_Misaligned_Address_Value;

   procedure Rcheck_PE_Missing_Return (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_26'Address);
   end Rcheck_PE_Missing_Return;

   procedure Rcheck_PE_Non_Transportable_Actual
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_31'Address);
   end Rcheck_PE_Non_Transportable_Actual;

   procedure Rcheck_PE_Overlaid_Controlled_Object
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_27'Address);
   end Rcheck_PE_Overlaid_Controlled_Object;

   procedure Rcheck_PE_Potentially_Blocking_Operation
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_28'Address);
   end Rcheck_PE_Potentially_Blocking_Operation;

   procedure Rcheck_PE_Stream_Operation_Not_Allowed
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_36'Address);
   end Rcheck_PE_Stream_Operation_Not_Allowed;

   procedure Rcheck_PE_Stubbed_Subprogram_Called
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_29'Address);
   end Rcheck_PE_Stubbed_Subprogram_Called;

   procedure Rcheck_PE_Unchecked_Union_Restriction
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Program_Error_Msg (File, Line, Rmsg_30'Address);
   end Rcheck_PE_Unchecked_Union_Restriction;

   procedure Rcheck_SE_Empty_Storage_Pool
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Storage_Error_Msg (File, Line, Rmsg_32'Address);
   end Rcheck_SE_Empty_Storage_Pool;

   procedure Rcheck_SE_Explicit_Raise (File : System.Address; Line : Integer)
   is
   begin
      Raise_Storage_Error_Msg (File, Line, Rmsg_33'Address);
   end Rcheck_SE_Explicit_Raise;

   procedure Rcheck_SE_Infinite_Recursion
     (File : System.Address; Line : Integer)
   is
   begin
      Raise_Storage_Error_Msg (File, Line, Rmsg_34'Address);
   end Rcheck_SE_Infinite_Recursion;

   procedure Rcheck_SE_Object_Too_Large (File : System.Address; Line : Integer)
   is
   begin
      Raise_Storage_Error_Msg (File, Line, Rmsg_35'Address);
   end Rcheck_SE_Object_Too_Large;

   procedure Rcheck_CE_Access_Check_Ext
     (File : System.Address; Line, Column : Integer)
   is
   begin
      Raise_Constraint_Error_Msg (File, Line, Column, Rmsg_00'Address);
   end Rcheck_CE_Access_Check_Ext;

   procedure Rcheck_CE_Index_Check_Ext
     (File : System.Address; Line, Column, Index, First, Last : Integer)
   is
      Msg : constant String :=
        Rmsg_05 (Rmsg_05'First .. Rmsg_05'Last - 1) & ASCII.LF & "index " &
        Image (Index) & " not in " & Image (First) & ".." & Image (Last) &
        ASCII.NUL;
   begin
      Raise_Constraint_Error_Msg (File, Line, Column, Msg'Address);
   end Rcheck_CE_Index_Check_Ext;

   procedure Rcheck_CE_Invalid_Data_Ext
     (File : System.Address; Line, Column, Index, First, Last : Integer)
   is
      Msg : constant String :=
        Rmsg_06 (Rmsg_06'First .. Rmsg_06'Last - 1) & ASCII.LF & "value " &
        Image (Index) & " not in " & Image (First) & ".." & Image (Last) &
        ASCII.NUL;
   begin
      Raise_Constraint_Error_Msg (File, Line, Column, Msg'Address);
   end Rcheck_CE_Invalid_Data_Ext;

   procedure Rcheck_CE_Range_Check_Ext
     (File : System.Address; Line, Column, Index, First, Last : Integer)
   is
      Msg : constant String :=
        Rmsg_12 (Rmsg_12'First .. Rmsg_12'Last - 1) & ASCII.LF & "value " &
        Image (Index) & " not in " & Image (First) & ".." & Image (Last) &
        ASCII.NUL;
   begin
      Raise_Constraint_Error_Msg (File, Line, Column, Msg'Address);
   end Rcheck_CE_Range_Check_Ext;

   procedure Rcheck_PE_Finalize_Raised_Exception
     (File : System.Address; Line : Integer)
   is
   begin
      --  This is "finalize/adjust raised exception". This subprogram is always
      --  called with abort deferred, unlike all other Rcheck_* subprograms, it
      --  needs to call Raise_Exception_No_Defer.

      --  This is consistent with Raise_From_Controlled_Operation
      Raise_Exception (Program_Error_Def'Access,
         "Rcheck_PE_Finalize_Raised_Exception");
   end Rcheck_PE_Finalize_Raised_Exception;

   -------------
   -- Reraise --
   -------------

   procedure Reraise is
   begin
      Raise_Exception (Program_Error_Def'Access, "Reraise");
   end Reraise;

   ------------------------
   -- Reraise_Occurrence --
   ------------------------

   procedure Reraise_Occurrence (X : Exception_Occurrence) is
   begin
      if X.Id = null then
         return;
      else
         Reraise_Occurrence_Always (X);
      end if;
   end Reraise_Occurrence;

   -------------------------------
   -- Reraise_Occurrence_Always --
   -------------------------------

   procedure Reraise_Occurrence_Always (X : Exception_Occurrence) is
   begin
      Raise_Exception (X.Id, "Reraise_Occurrence_Always");
   end Reraise_Occurrence_Always;

   ---------------------------------
   -- Reraise_Occurrence_No_Defer --
   ---------------------------------

   procedure Reraise_Occurrence_No_Defer (X : Exception_Occurrence) is
   begin
      --  If we have a Machine_Occurrence at hand already, e.g. when we are
      --  reraising a foreign exception, just repropagate. Otherwise, e.g.
      --  when reraising a GNAT exception or an occurrence read back from a
      --  stream, set up a new occurrence with its own Machine block first.
      Raise_Exception (X.Id, "Reraise_Occurrence_No_Defer");
   end Reraise_Occurrence_No_Defer;

end Ada.Exceptions;
