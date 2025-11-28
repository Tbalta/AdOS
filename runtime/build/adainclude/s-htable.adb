------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                        S Y S T E M . H T A B L E                         --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                    Copyright (C) 1995-2023, AdaCore                      --
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

with System.String_Hash;

package body System.HTable is

   -------------------
   -- Static_HTable --
   -------------------

   package body Static_HTable is

      Table : array (Header_Num) of Elmt_Ptr;

      Iterator_Index   : Header_Num;
      Iterator_Ptr     : Elmt_Ptr;
      Iterator_Started : Boolean := False;

      function Get_Non_Null return Elmt_Ptr;
      --  Returns Null_Ptr if Iterator_Started is false or the Table is empty.
      --  Returns Iterator_Ptr if non null, or the next non null element in
      --  table if any.

      ---------
      -- Get --
      ---------

      function Get (K : Key) return Elmt_Ptr is
         Elmt : Elmt_Ptr;

      begin
         Elmt := Table (Hash (K));
         loop
            if Elmt = Null_Ptr then
               return Null_Ptr;

            elsif Equal (Get_Key (Elmt), K) then
               return Elmt;

            else
               Elmt := Next (Elmt);
            end if;
         end loop;
      end Get;

      ---------------
      -- Get_First --
      ---------------

      function Get_First return Elmt_Ptr is
      begin
         Iterator_Started := True;
         Iterator_Index   := Table'First;
         Iterator_Ptr     := Table (Iterator_Index);
         return Get_Non_Null;
      end Get_First;

      --------------
      -- Get_Next --
      --------------

      function Get_Next return Elmt_Ptr is
      begin
         if not Iterator_Started then
            return Null_Ptr;
         else
            Iterator_Ptr := Next (Iterator_Ptr);
            return Get_Non_Null;
         end if;
      end Get_Next;

      ------------------
      -- Get_Non_Null --
      ------------------

      function Get_Non_Null return Elmt_Ptr is
      begin
         while Iterator_Ptr = Null_Ptr loop
            if Iterator_Index = Table'Last then
               Iterator_Started := False;
               return Null_Ptr;
            end if;

            Iterator_Index := Iterator_Index + 1;
            Iterator_Ptr   := Table (Iterator_Index);
         end loop;

         return Iterator_Ptr;
      end Get_Non_Null;

      -------------
      -- Present --
      -------------

      function Present (K : Key) return Boolean is
      begin
         return Get (K) /= Null_Ptr;
      end Present;

      ------------
      -- Remove --
      ------------

      procedure Remove  (K : Key) is
         Index     : constant Header_Num := Hash (K);
         Elmt      : Elmt_Ptr;
         Next_Elmt : Elmt_Ptr;

      begin
         Elmt := Table (Index);

         if Elmt = Null_Ptr then
            return;

         elsif Equal (Get_Key (Elmt), K) then
            Table (Index) := Next (Elmt);

         else
            loop
               Next_Elmt := Next (Elmt);

               if Next_Elmt = Null_Ptr then
                  return;

               elsif Equal (Get_Key (Next_Elmt), K) then
                  Set_Next (Elmt, Next (Next_Elmt));
                  return;

               else
                  Elmt := Next_Elmt;
               end if;
            end loop;
         end if;
      end Remove;

      -----------
      -- Reset --
      -----------

      procedure Reset is
      begin
         --  Use an aggregate for efficiency reasons

         Table := [others => Null_Ptr];
      end Reset;

      ---------
      -- Set --
      ---------

      procedure Set (E : Elmt_Ptr) is
         Index : Header_Num;
      begin
         Index := Hash (Get_Key (E));
         Set_Next (E, Table (Index));
         Table (Index) := E;
      end Set;

      ------------------------
      -- Set_If_Not_Present --
      ------------------------

      function Set_If_Not_Present (E : Elmt_Ptr) return Boolean is
         K : Key renames Get_Key (E);
         --  Note that it is important to use a renaming here rather than
         --  define a constant initialized by the call, because the latter
         --  construct runs into bootstrap problems with earlier versions
         --  of the GNAT compiler.

         Index : constant Header_Num := Hash (K);
         Elmt  : Elmt_Ptr;

      begin
         Elmt := Table (Index);
         loop
            if Elmt = Null_Ptr then
               Set_Next (E, Table (Index));
               Table (Index) := E;
               return True;

            elsif Equal (Get_Key (Elmt), K) then
               return False;

            else
               Elmt := Next (Elmt);
            end if;
         end loop;
      end Set_If_Not_Present;

   end Static_HTable;

   ----------
   -- Hash --
   ----------

   function Hash (Key : String) return Header_Num is
      type Uns is mod 2 ** 32;

      function Hash_Fun is
         new System.String_Hash.Hash (Character, String, Uns);

   begin
      return Header_Num'First +
        Header_Num'Base (Hash_Fun (Key) mod Header_Num'Range_Length);
   end Hash;

end System.HTable;
