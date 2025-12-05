------------------------------------------------------------------------------
--                                 VGA-CRTC                                 --
--                                                                          --
--                                 S p e c                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
--                                                                          --
--  Description:                                                            --
--    register definition for CRTC registers                                --
------------------------------------------------------------------------------

with System;
with x86.Port_IO;
with Interfaces; use Interfaces;

package VGA.CRTC is
   pragma Preelaborate;

   procedure Set_Horizontal_Blanking (start : Positive; duration : Positive);
   procedure Set_Horizontal_Retrace (Start : Character_Count; Duration : Character_Count);
   procedure Set_Vertical_Blanking (Start : Natural; Duration : Natural);
   procedure Set_Vertical_Retrace (start : Natural; duration : Natural);
   procedure Set_Vertical_Total (total : Scan_Line_Count);
   procedure Set_Vertical_Display (display : Natural);
   procedure Set_Line_Compare (Line : Natural);
   procedure Set_CRTC_For_Mode (mode : VGA_mode);

   -----------------
   -- CRTC Values --
   -----------------
   type bit is range 0 .. 1;
   for bit'Size use 1;

   -- End_Blanking --
   subtype End_Blanking_LSB is Unsigned_5;
   subtype End_Blanking_MSB is bit;
   type End_Blanking_T (Bit_Access : Boolean) is record
      case Bit_Access is
         when True =>
            LSB : End_Blanking_LSB;
            MSB : End_Blanking_MSB;

         when False =>
            Value : Unsigned_6;
      end case;
   end record;
   for End_Blanking_T use
     record
       LSB at 0 range 0 .. 4;
       MSB at 0 range 5 .. 5;
       Value at 0 range 0 .. 5;
     end record;
   pragma Unchecked_Union (End_Blanking_T);

   -- Vertical_Total --
   subtype Vertical_Total_LSB is Unsigned_8;
   subtype Vertical_Total_VT8 is bit;
   subtype Vertical_Total_VT9 is bit;
   type Vertical_Total_T (Bit_Access : Boolean := False) is record
      case Bit_Access is
         when True =>
            LSB : Vertical_Total_LSB;
            VT8 : Vertical_Total_VT8;
            VT9 : Vertical_Total_VT9;

         when False =>
            Value : Unsigned_10;
      end case;
   end record
   with Size => 10;
   pragma Unchecked_Union (Vertical_Total_T);
   for Vertical_Total_T use
     record
       LSB at 0 range 0 .. 7;
       VT8 at 0 range 8 .. 8;
       VT9 at 0 range 9 .. 9;
       Value at 0 range 0 .. 9;
     end record;

   -- Line_Compare --
   subtype Line_Compare_LSB is Unsigned_8;
   subtype Line_Compare_LC8 is bit;
   subtype Line_Compare_LC9 is bit;
   type Line_Compare_T (Bit_Access : Boolean) is record
      case Bit_Access is
         when True =>
            LSB : Line_Compare_LSB;
            LC8 : Line_Compare_LC8;
            LC9 : Line_Compare_LC9;

         when False =>
            Value : Unsigned_10;
      end case;
   end record
   with Size => 10;
   pragma Unchecked_Union (Line_Compare_T);
   for Line_Compare_T use
     record
       LSB at 0 range 0 .. 7;
       LC8 at 0 range 8 .. 8;
       LC9 at 0 range 9 .. 9;
       Value at 0 range 0 .. 9;
     end record;

   -- Line_Compare --
   type Start_Address_MSB is new Unsigned_8;
   type Start_Address_LSB is new Unsigned_8;
   type Start_Address_T (Bit_Access : Boolean) is record
      case Bit_Access is
         when True =>
            Address_LSB : Start_Address_LSB;
            Address_MSB : Start_Address_MSB;

         when False =>
            Value : Unsigned_16;
      end case;
   end record
   with Size => 16;
   pragma Unchecked_Union (Start_Address_T);
   for Start_Address_T use
     record
       Address_LSB at 0 range 0 .. 7;
       Address_MSB at 0 range 8 .. 15;
       Value at 0 range 0 .. 15;
     end record;

   -- Start_Vertical_Blanking --
   subtype Start_Vertical_Blanking_LSB is Unsigned_8;
   subtype Start_Vertical_Blanking_VSB8 is bit;
   subtype Start_Vertical_Blanking_VSB9 is bit;
   type Start_Vertical_Blanking_T (Bit_Access : Boolean) is record
      case Bit_Access is
         when True =>
            LSB  : Start_Vertical_Blanking_LSB;
            VSB8 : Start_Vertical_Blanking_VSB8;
            VSB9 : Start_Vertical_Blanking_VSB9;

         when False =>
            Value : Unsigned_10;
      end case;
   end record
   with Size => 10;
   pragma Unchecked_Union (Start_Vertical_Blanking_T);
   for Start_Vertical_Blanking_T use
     record
       LSB at 0 range 0 .. 7;
       VSB8 at 0 range 8 .. 8;
       VSB9 at 0 range 9 .. 9;
       Value at 0 range 0 .. 9;
     end record;

   -- Vertical_Display_Enable_End --
   subtype Vertical_Display_Enable_End_LSB is Unsigned_8;
   subtype Vertical_Display_Enable_End_VDE9 is bit;
   subtype Vertical_Display_Enable_End_VDE8 is bit;
   type Vertical_Display_Enable_End_T (Bit_Access : Boolean) is record
      case Bit_Access is
         when True =>
            LSB  : Vertical_Display_Enable_End_LSB;
            VDE8 : Vertical_Display_Enable_End_VDE8;
            VDE9 : Vertical_Display_Enable_End_VDE9;

         when False =>
            Value : Unsigned_10;
      end case;
   end record
   with Size => 10;
   pragma Unchecked_Union (Vertical_Display_Enable_End_T);
   for Vertical_Display_Enable_End_T use
     record
       LSB at 0 range 0 .. 7;
       VDE8 at 0 range 8 .. 8;
       VDE9 at 0 range 9 .. 9;
       Value at 0 range 0 .. 9;
     end record;

   -- Vertical_Retrace_Start --
   subtype Vertical_Retrace_Start_LSB is Unsigned_8;
   subtype Vertical_Retrace_Start_VRS9 is bit;
   subtype Vertical_Retrace_Start_VRS8 is bit;
   type Vertical_Retrace_Start_T (Bit_Access : Boolean) is record
      case Bit_Access is
         when True =>
            LSB  : Vertical_Retrace_Start_LSB;
            VRS8 : Vertical_Retrace_Start_VRS8;
            VRS9 : Vertical_Retrace_Start_VRS9;

         when False =>
            Value : Unsigned_10;
      end case;
   end record
   with Size => 10;
   pragma Unchecked_Union (Vertical_Retrace_Start_T);
   for Vertical_Retrace_Start_T use
     record
       LSB at 0 range 0 .. 7;
       VRS8 at 0 range 8 .. 8;
       VRS9 at 0 range 9 .. 9;
       Value at 0 range 0 .. 9;
     end record;

  
private


end VGA.CRTC;
