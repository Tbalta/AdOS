------------------------------------------------------------------------------
--                             CIRCULAR_BUFFER                              --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

generic
   Max_Size : Integer := 256;
   type Element_Type is private;
package Circular_Buffer is
   pragma Pure;
   subtype Buffer_Index is Integer range 0 .. (Max_Size - 1);
   type Element_Array is array (Buffer_Index) of Element_Type;

   type Buffer_Type is record
      Tail   : Buffer_Index := 0;
      Head   : Buffer_Index := 0;
      Buffer : Element_Array;
   end record;
   pragma Preelaborable_Initialization (Buffer_Type);

   type Dequeue_Result (valid : Boolean) is record
      case Valid is
         when True =>
            Value : Element_Type;

         when False =>
            null;
      end case;
   end record;
   function Pop (Buffer : access Buffer_Type) return Dequeue_Result;
   procedure Push (Buffer : access Buffer_Type; item : in Element_Type);
   function Count (Buffer : Buffer_Type) return Integer;

end Circular_Buffer;
