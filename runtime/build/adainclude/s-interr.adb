------------------------------------------------------------------------------
--                                                                          --
--                 GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                 --
--                                                                          --
--                     S Y S T E M . I N T E R R U P T S                    --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--         Copyright (C) 1992-2023, Free Software Foundation, Inc.          --
--                                                                          --
-- GNARL is free software; you can  redistribute it  and/or modify it under --
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
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by Ada Core Technologies, Inc.     --
--                                                                          --
------------------------------------------------------------------------------

--  Invariants:

--  All user-handleable interrupts are masked at all times in all tasks/threads
--  except possibly for the Interrupt_Manager task.

--  When a user task wants to achieve masking/unmasking an interrupt, it must
--  call Block_Interrupt/Unblock_Interrupt, which will have the effect of
--  unmasking/masking the interrupt in the Interrupt_Manager task.

--  Note : Direct calls to sigaction, sigprocmask, pthread_sigsetmask or any
--  other low-level interface that changes the interrupt action or
--  interrupt mask needs a careful thought.

--  One may achieve the effect of system calls first masking RTS blocked
--  (by calling Block_Interrupt) for the interrupt under consideration.
--  This will make all the tasks in RTS blocked for the Interrupt.

--  Once we associate a Server_Task with an interrupt, the task never goes
--  away, and we never remove the association.

--  There is no more than one interrupt per Server_Task and no more than one
--  Server_Task per interrupt.

package body System.Interrupts is

   function Is_Reserved (Interrupt : Interrupt_ID) return Boolean
   is
   pragma Unreferenced (Interrupt);
   begin
      return False;
   end Is_Reserved;

   function Is_Entry_Attached (Interrupt : Interrupt_ID) return Boolean
   is
   pragma Unreferenced (Interrupt);
   begin
      return False;
   end Is_Entry_Attached;

   function Is_Handler_Attached (Interrupt : Interrupt_ID) return Boolean
   is
   pragma Unreferenced (Interrupt);
   begin
      return False;
   end Is_Handler_Attached;

   function Current_Handler
   (Interrupt : Interrupt_ID) return Parameterless_Handler is
   pragma Unreferenced (Interrupt);
   begin
      return null;
   end Current_Handler;

   procedure Attach_Handler
     (New_Handler : Parameterless_Handler;
      Interrupt   : Interrupt_ID;
      Static      : Boolean := False) is
   pragma Unreferenced (New_Handler, Interrupt, Static);
   begin
      null;
   end Attach_Handler;

   procedure Exchange_Handler
     (Old_Handler : out Parameterless_Handler;
      New_Handler : Parameterless_Handler;
      Interrupt   : Interrupt_ID;
      Static      : Boolean := False)
   is
   pragma Unreferenced (New_Handler, Interrupt, Static);
   begin
      Old_Handler := null;
   end Exchange_Handler;

   procedure Detach_Handler
     (Interrupt : Interrupt_ID;
      Static    : Boolean := False)
   is
   pragma Unreferenced (Interrupt, Static);
   begin
      null;
   end Detach_Handler;

   function Reference
     (Interrupt : Interrupt_ID) return System.Address
   is
   pragma Unreferenced (Interrupt);
   begin
      return System.Null_Address;
   end Reference;

   procedure Register_Interrupt_Handler
     (Handler_Addr : System.Address)
   is
   pragma Unreferenced (Handler_Addr);
   begin
      null;
   end Register_Interrupt_Handler;

   procedure Install_Restricted_Handlers
     (Prio     : Interrupt_Priority;
      Handlers : New_Handler_Array)
   is
   pragma Unreferenced (Prio, Handlers);
   begin
      null;
   end Install_Restricted_Handlers;

end System.Interrupts;