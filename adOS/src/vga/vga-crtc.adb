------------------------------------------------------------------------------
--                                 VGA-CRTC                                 --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with VGA.CRTC;
with x86.Port_Io;
with Ada.Unchecked_Conversion;
with SERIAL;
with VGA.GTF; use VGA.GTF;
with Interfaces; use Interfaces;
with Log;

with VGA.CRTC.Registers;   use VGA.CRTC.Registers;
package body VGA.CRTC is
   package Logger renames Log.Serial_Logger;


   -- Prepare_CRTC_For_Configuration --
   procedure Prepare_CRTC_For_Configuration is
   begin
      Write_End_Horizontal_Blanking_Register ((others => <>));
      Write_End_Horizontal_Retrace_Register ((others => <>));
      Write_Vertical_Retrace_End_Register
        ((Clear_Vertical_Interrupt  => False,
          Enable_Vertical_Interrupt => False,
          Select_5_Refresh_Cycles   => False,
          Protect_Register          => False,
          others                    => 0));
      Write_Maximum_Scan_Line_Register ((others => <>));
      Write_Start_Address_High_Register (0);
      Write_Start_Address_Low_Register (0);

      Write_Cursor_Location_High_Register (0);
      Write_Cursor_Location_Low_Register (0);
   end Prepare_CRTC_For_Configuration;

   ------------------------
   -- Get_MSL_Multiplier --
   ------------------------
   function Get_MSL_Multiplier (Height : Scan_Line_Count) return Integer is
      HW_MAX_SUPPORTED_HEIGHT : constant Scan_Line_Count := 400;
   begin
      if HW_MAX_SUPPORTED_HEIGHT < Height then
         return 1;
   end if;

      return HW_MAX_SUPPORTED_HEIGHT / Height;
   end Get_MSL_Multiplier;

   function Compute_Dot_Per_Pixel (Color_Depth : Positive) return Positive is
   begin
      if Color_Depth = 256 then
         -- In 256 mode 4 pixels are outputed from memory each dot clock
         -- Hence, 2 dot ticks are required for 1 pixel.
         return 2;
      else
         return 1;
      end if;
   end Compute_Dot_Per_Pixel;


   procedure Set_CRTC_For_Mode (mode : VGA_mode)
   is
      Timing : VGA_Timing;
      Line_Compare_Disable : constant := 16#3FF#;
      Offset     : Positive;
   begin
      if mode.vga_type = alphanumeric then
         Offset := mode.AN_Format.Width / (1 * 2);
         Timing := Compute_Timing (mode.Pixel_Width, mode.Pixel_Height);
      else
         Offset := mode.Pixel_Width / (2 * 2 * 2);
         Timing := Compute_Timing (mode.Pixel_Width * Compute_Dot_Per_Pixel (mode.Colors), mode.Pixel_Height * Get_MSL_Multiplier (mode.Pixel_Height));
      end if;
      Logger.Log_Info ("Setting CRTC for mode" & mode'Image);
      Logger.Log_Info (Timing'Image);
      Prepare_CRTC_For_Configuration;

      Write_Horizontal_Total_Register (Horizontal_Total_Register (Timing.Total_H - 5));
      Write_Horizontal_Display_Enable_End_Register
        (Horizontal_Display_Enable_End_Register (Timing.Active_H_Chars - 1));
      Set_Horizontal_Blanking (Timing.H_Blanking_Start, Timing.H_Blanking_Duration);
      Set_Horizontal_Retrace (Timing.H_Retrace_Start, Timing.H_Retrace_Duration);

      Set_Vertical_Total (Timing.Total_V - 2);
      Set_Vertical_Display (Timing.Active_V_Chars - 1);
      Set_Vertical_Blanking (Timing.V_Blanking_Start, Timing.V_Blanking_Duration);
      Set_Vertical_Retrace (Timing.V_Retrace_Start, Timing.V_Retrace_Duration);

      Write_Cursor_Start_Register ((Row_Scan_Cursor_Begins => 16#D#, Cursor_Off => False));
      Write_Cursor_End_Register ((Row_Scan_Cursor_Ends => 16#E#, Cursor_Skew_Control => 0));

      Write_Offset_Register (Offset_Register (Offset));

      if mode.vga_type = alphanumeric then
         Write_Underline_Location_Register
         ((Start_Under_Line => 16#1F#, Count_By_4 => False, Double_Word => False, others => <>));
      else
         Write_Underline_Location_Register
         ((Start_Under_Line => 16#0#, Count_By_4 => False, Double_Word => True, others => <>));
      end if;

      if mode.vga_type = alphanumeric then
         Write_Maximum_Scan_Line_Register
         ((MSL => Unsigned_5 (mode.Box.Height * 2) - 1, Double_Scanning => False, others => 0));
      else
         Write_Maximum_Scan_Line_Register
         ((MSL => Unsigned_5 (Get_MSL_Multiplier (mode.Pixel_Height) - 1), Double_Scanning => False, others => 0));
      end if;
      Set_Line_Compare (Line_Compare_Disable);

         Write_CRT_Mode_Control_Register
         ((CSM_0          => True,
            SRC            => True,
            HRS            => False,
            Count_By_2     => False,
            Address_Wrap   => True,
            Word_Byte_Mode => False,
            Hardware_Reset => True));

      Write_Cursor_Location_Low_Register (16#50#);

   end Set_CRTC_For_Mode;

   procedure Set_Horizontal_Blanking (start : Positive; duration : Positive) is
      --  To program Horizontal_Blanking_End for a signal width of W, the
      --  following algorithm is used: the width W, in character
      --  clock units, is added to the value from the Start
      --  Horizontal Blanking register. The 6 low-order bits of the
      --  result are the 6-bit value programmed
      Horizontal_Blanking_End : Natural := (Start + Duration) mod 2 ** End_Blanking_T'Size;
      Blanking_End_Breakdown  : End_Blanking_T :=
        (Value => Unsigned_6 (Horizontal_Blanking_End), Bit_Access => False);

      EHB_Register : End_Horizontal_Blanking_Register := Read_End_Horizontal_Blanking_Register;
      EHR_Register : End_Horizontal_Retrace_Register := Read_End_Horizontal_Retrace_Register;
   begin
      Write_Start_Horizontal_Blanking_Register (Horizontal_Blanking_Start (start));

      EHB_Register.End_Blanking := Blanking_End_Breakdown.LSB;
      Write_End_Horizontal_Blanking_Register (EHB_Register);

      EHR_Register.EB5 := Blanking_End_Breakdown.MSB;
      Write_End_Horizontal_Retrace_Register (EHR_Register);
   end Set_Horizontal_Blanking;

   procedure Set_Horizontal_Retrace (Start : Character_Count; Duration : Character_Count) is
      --  To program these bits with a signal width of W, the
      --  following algorithm is used: the width W, in character
      --  clock units, is added to the value in the Start Retrace
      --  register. The 5 low-order bits of the result are the 5-bit
      --  value programmed.
      HR_End : Unsigned_5 := Unsigned_5 ((Start + Duration) mod 2 ** Unsigned_5'Size);

      EHR_Register : End_Horizontal_Retrace_Register := Read_End_Horizontal_Retrace_Register;
   begin
      Write_Start_Horizontal_Retrace_Pulse_Register
        (Start_Horizontal_Retrace_Pulse_Register (Start));

      EHR_Register.EHR := Unsigned_5 (HR_End);
      Write_End_Horizontal_Retrace_Register (EHR_Register);
   end Set_Horizontal_Retrace;

   procedure Set_Vertical_Blanking (Start : Natural; Duration : Natural) is
      Start_Vertical_Blanking : Start_Vertical_Blanking_T :=
        (Value => Unsigned_10 (Start), Bit_Access => False);
      --  To program the End Blanking Register with a âvertical blankingâ signal of width W,
      --  the following algorithm is used: the width W, in horizontal scan
      --  line units, is added to the value in the Start Vertical Blanking
      --  register minus 1. The 8 low-order bits of the result are the 8-bit
      --  value programmed.
      Vertical_Blanking_End   : Natural :=
        (Start + Duration - 1) mod 2 ** End_Vertical_Blanking_Register'Size;

      Overflow          : Overflow_Register := Read_Overflow_Register;
      Maximum_Scan_Line : Maximum_Scan_Line_Register := Read_Maximum_Scan_Line_Register;
   begin
      Overflow.VBS8 := Start_Vertical_Blanking.VSB8;
      Maximum_Scan_Line.VBS9 := Start_Vertical_Blanking.VSB9;

      Write_Start_Vertical_Blanking_Register (Start_Vertical_Blanking.LSB);
      Write_Overflow_Register (Overflow);
      Write_Maximum_Scan_Line_Register (Maximum_Scan_Line);
      Write_End_Vertical_Blanking_Register (End_Vertical_Blanking_Register (Vertical_Blanking_End));
   end Set_Vertical_Blanking;

   procedure Set_Vertical_Retrace (start : Natural; duration : Natural) is
      Start_Vertical_Retrace : Vertical_Retrace_Start_T :=
        (Value => Unsigned_10 (start), Bit_Access => False);

      --  To program the End Vertical Retrace bits with a signal width of W,
      --  the following algorithm is used: the width W, in
      --  horizontal scan units, is added to the value in the Start
      --  Vertical Retrace register. The 4 low-order bits of the
      --  result are the 4-bit value programmed.
      Vertical_Retrace_End : Unsigned_4 := Unsigned_4 ((Start + Duration) mod 2 ** Unsigned_4'Size);

      VRE_Register : Vertical_Retrace_End_Register := Read_Vertical_Retrace_End_Register;
      Overflow     : Overflow_Register := Read_Overflow_Register;
   begin
      Write_Vertical_Retrace_Start_Register (Start_Vertical_Retrace.LSB);

      Overflow.VRS8 := Start_Vertical_Retrace.VRS8;
      Overflow.VRS9 := Start_Vertical_Retrace.VRS9;
      Write_Overflow_Register (Overflow);

      VRE_Register.VRE := Vertical_Retrace_End;
      Write_Vertical_Retrace_End_Register (VRE_Register);
   end Set_Vertical_Retrace;

   procedure Set_Vertical_Total (total : Scan_Line_Count) is
      Vertical_Total : Vertical_Total_T := (Value => Unsigned_10 (total), Bit_Access => False);
      Overflow       : Overflow_Register := Read_Overflow_Register;
   begin
      Write_Vertical_Total_Register (Vertical_Total.LSB);
      Overflow.VT8 := Vertical_Total.VT8;
      Overflow.VT9 := Vertical_Total.VT9;
      Write_Overflow_Register (Overflow);
   end Set_Vertical_Total;

   procedure Set_Vertical_Display (display : Natural) is
      Vertical_Displayed : Vertical_Display_Enable_End_T :=
        (Value => Unsigned_10 (display), Bit_Access => False);

      Overflow : Overflow_Register := Read_Overflow_Register;
   begin
      Write_Vertical_Display_Enable_End_Register (Vertical_Displayed.LSB);
      Overflow.VDE8 := Vertical_Displayed.VDE8;
      Overflow.VDE9 := Vertical_Displayed.VDE9;
      Write_Overflow_Register (Overflow);
   end Set_Vertical_Display;

   procedure Set_Line_Compare (Line : Natural) is
      Line_Compare : Line_Compare_T := (Value => Unsigned_10 (Line), Bit_Access => False);
      MSL_Register : Maximum_Scan_Line_Register := Read_Maximum_Scan_Line_Register;
      Overflow     : Overflow_Register := Read_Overflow_Register;
   begin
      Write_Line_Compare_register (Line_Compare.LSB);

      Overflow.LC8 := Line_Compare.LC8;
      Write_Overflow_Register (Overflow);

      MSL_Register.LC9 := Line_Compare.LC9;
      Write_Maximum_Scan_Line_Register (MSL_Register);
   end Set_Line_Compare;
end VGA.CRTC;
