with VGA.CRTC;
with x86.Port_Io;
with Ada.Unchecked_Conversion;
with SERIAL;
with Interfaces; use Interfaces;

package body VGA.CRTC is

   ----------------------------------------
   --           Write_Register           --
   --                                    --
   --  type Data_Type is private;        --
   --  Index : CRTC_Registers;           --
   ----------------------------------------
   procedure Write_Register (Value : Data_Type) is
      procedure Write is new x86.Port_IO.Write_Port_8 (Data_Register_Address, Data_Type);
      function To_U8 is new Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Data_Type);
   begin
      Register_Array (Index) := To_U8 (Value);
      Write_Address (Index);
      Write (Value);
      SERIAL.send_string (Value'Image & "| is ");
      SERIAL.send_hex (Unsigned_32 (To_U8 (Value)));
      SERIAL.send_line ("");
   end Write_Register;

   procedure Dump_CRTC_Register is
      function To_U8_Horizontal_Total is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Horizontal_Total_Register);
      function To_U8_Horizontal_Display_Enable_End is new
        Ada.Unchecked_Conversion
          (Target => Unsigned_8,
           Source => Horizontal_Display_Enable_End_Register);
      function To_U8_Start_Horizontal_Blanking is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Horizontal_Blanking_Start);
      function To_U8_End_Horizontal_Blanking is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => End_Horizontal_Blanking_Register);
      function To_U8_Start_Horizontal_Retrace_Pulse is new
        Ada.Unchecked_Conversion
          (Target => Unsigned_8,
           Source => Start_Horizontal_Retrace_Pulse_Register);
      function To_U8_End_Horizontal_Retrace is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => End_Horizontal_Retrace_Register);
      function To_U8_Vertical_Total is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Vertical_Total_Register);
      function To_U8_Overflow is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Overflow_Register);
      function To_U8_Preset_Row_Scan is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Preset_Row_Scan_Register);
      function To_U8_Maximum_Scan_Line is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Maximum_Scan_Line_Register);
      function To_U8_Cursor_Start is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Cursor_Start_Register);
      function To_U8_Cursor_End is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Cursor_End_Register);
      function To_U8_Start_Address_High is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Start_Address_High_Register);
      function To_U8_Start_Address_Low is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Start_Address_Low_Register);
      function To_U8_Cursor_Location_High is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Cursor_Location_High_Register);
      function To_U8_Cursor_Location_Low is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Cursor_Location_Low_Register);
      function To_U8_Vertical_Retrace_Start is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Vertical_Retrace_Start_Register);
      function To_U8_Vertical_Retrace_End is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Vertical_Retrace_End_Register);
      function To_U8_Vertical_Display_Enable_End is new
        Ada.Unchecked_Conversion
          (Target => Unsigned_8,
           Source => Vertical_Display_Enable_End_Register);
      function To_U8_Offset is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Offset_Register);
      function To_U8_Underline_Location is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Underline_Location_Register);
      function To_U8_Start_Vertical_Blanking is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Start_Vertical_Blanking_Register);
      function To_U8_End_Vertical_Blanking is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => End_Vertical_Blanking_Register);
      function To_U8_CRT_Mode_Control is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => CRT_Mode_Control_Register);
      function To_U8_Line_Compare is new
        Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Line_Compare_Register);
   begin
      for I in Register_Array'Range loop
         SERIAL.send_string (I'image & "-> ");
         SERIAL.send_hex (Unsigned_32 (Register_Array (I)));
         SERIAL.send_line ("");
      end loop;
      SERIAl.send_line (Read_Maximum_Scan_Line_Register'Image);
      --  SERIAL.send_line (Register_Array'Image);
      SERIAL.send_hex (Unsigned_32 (To_U8_Horizontal_Total (Read_Horizontal_Total_Register)));
      SERIAL.send_hex
        (Unsigned_32
           (To_U8_Horizontal_Display_Enable_End (Read_Horizontal_Display_Enable_End_Register)));
      SERIAL.send_hex
        (Unsigned_32 (To_U8_Start_Horizontal_Blanking (Read_Start_Horizontal_Blanking_Register)));
      SERIAL.send_hex
        (Unsigned_32 (To_U8_End_Horizontal_Blanking (Read_End_Horizontal_Blanking_Register)));
      SERIAL.send_hex
        (Unsigned_32
           (To_U8_Start_Horizontal_Retrace_Pulse (Read_Start_Horizontal_Retrace_Pulse_Register)));
      SERIAL.send_hex
        (Unsigned_32 (To_U8_End_Horizontal_Retrace (Read_End_Horizontal_Retrace_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Vertical_Total (Read_Vertical_Total_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Overflow (Read_Overflow_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Preset_Row_Scan (Read_Preset_Row_Scan_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Maximum_Scan_Line (Read_Maximum_Scan_Line_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Cursor_Start (Read_Cursor_Start_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Cursor_End (Read_Cursor_End_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Start_Address_High (Read_Start_Address_High_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Start_Address_Low (Read_Start_Address_Low_Register)));
      SERIAL.send_hex
        (Unsigned_32 (To_U8_Cursor_Location_High (Read_Cursor_Location_High_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Cursor_Location_Low (Read_Cursor_Location_Low_Register)));
      SERIAL.send_hex
        (Unsigned_32 (To_U8_Vertical_Retrace_Start (Read_Vertical_Retrace_Start_Register)));
      SERIAL.send_hex
        (Unsigned_32 (To_U8_Vertical_Retrace_End (Read_Vertical_Retrace_End_Register)));
      SERIAL.send_hex
        (Unsigned_32
           (To_U8_Vertical_Display_Enable_End (Read_Vertical_Display_Enable_End_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Offset (Read_Offset_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Underline_Location (Read_Underline_Location_Register)));
      SERIAL.send_hex
        (Unsigned_32 (To_U8_Start_Vertical_Blanking (Read_Start_Vertical_Blanking_Register)));
      SERIAL.send_hex
        (Unsigned_32 (To_U8_End_Vertical_Blanking (Read_End_Vertical_Blanking_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_CRT_Mode_Control (Read_CRT_Mode_Control_Register)));
      SERIAL.send_hex (Unsigned_32 (To_U8_Line_Compare (Read_Line_Compare_Register)));
      SERIAL.send_line ("");
   end Dump_CRTC_Register;

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



   ----------------------------------------
   --            Read_Register           --
   --                                    --
   --  type Data_Type is private;        --
   --  Index : CRTC_Registers;           --
   ----------------------------------------
   function Read_Register return Data_Type is
      function Read is new x86.Port_IO.Read_Port_8 (Data_Register_Address, Data_Type);
   begin
      Write_Address (Index);
      return Read;
   end Read_Register;

   ----------------------------------
   -- Register Specific Read/Write --
   ----------------------------------
   -- Horizontal_Total_Register --
   procedure Write_Horizontal_Total_Register (Register : Horizontal_Total_Register) is
      procedure Write is new Write_Register (Horizontal_Total_Register, Horizontal_Total);
   begin
      Write (Register);
   end Write_Horizontal_Total_Register;

   function Read_Horizontal_Total_Register return Horizontal_Total_Register is
      function Read is new Read_Register (Horizontal_Total_Register, Horizontal_Total);
   begin
      return Read;
   end Read_Horizontal_Total_Register;


   -- Horizontal_Display_Enable_End_Register --
   procedure Write_Horizontal_Display_Enable_End_Register
     (Register : Horizontal_Display_Enable_End_Register)
   is
      procedure Write is new
        Write_Register (Horizontal_Display_Enable_End_Register, Horizontal_Display_Enable_End);
   begin
      Write (Register);
   end Write_Horizontal_Display_Enable_End_Register;

   function Read_Horizontal_Display_Enable_End_Register
      return Horizontal_Display_Enable_End_Register
   is
      function Read is new
        Read_Register (Horizontal_Display_Enable_End_Register, Horizontal_Display_Enable_End);
   begin
      return Read;
   end Read_Horizontal_Display_Enable_End_Register;


   -- Start_Horizontal_Blanking_Register --
   procedure Write_Start_Horizontal_Blanking_Register (Register : Horizontal_Blanking_Start) is
      procedure Write is new Write_Register (Horizontal_Blanking_Start, Start_Horizontal_Blanking);
   begin
      Write (Register);
   end Write_Start_Horizontal_Blanking_Register;

   function Read_Start_Horizontal_Blanking_Register return Horizontal_Blanking_Start is
      function Read is new Read_Register (Horizontal_Blanking_Start, Start_Horizontal_Blanking);
   begin
      return Read;
   end Read_Start_Horizontal_Blanking_Register;


   -- End_Horizontal_Blanking_Register --
   procedure Write_End_Horizontal_Blanking_Register (Register : End_Horizontal_Blanking_Register) is
      procedure Write is new
        Write_Register (End_Horizontal_Blanking_Register, End_Horizontal_Blanking);
   begin
      Write (Register);
   end Write_End_Horizontal_Blanking_Register;

   function Read_End_Horizontal_Blanking_Register return End_Horizontal_Blanking_Register is
      function Read is new
        Read_Register (End_Horizontal_Blanking_Register, End_Horizontal_Blanking);
   begin
      return Read;
   end Read_End_Horizontal_Blanking_Register;


   -- Start_Horizontal_Retrace_Pulse_Register --
   procedure Write_Start_Horizontal_Retrace_Pulse_Register
     (Register : Start_Horizontal_Retrace_Pulse_Register)
   is
      procedure Write is new
        Write_Register (Start_Horizontal_Retrace_Pulse_Register, Start_Horizontal_Retrace_Pulse);
   begin
      Write (Register);
   end Write_Start_Horizontal_Retrace_Pulse_Register;

   function Read_Start_Horizontal_Retrace_Pulse_Register
      return Start_Horizontal_Retrace_Pulse_Register
   is
      function Read is new
        Read_Register (Start_Horizontal_Retrace_Pulse_Register, Start_Horizontal_Retrace_Pulse);
   begin
      return Read;
   end Read_Start_Horizontal_Retrace_Pulse_Register;


   -- End_Horizontal_Retrace_Register --
   procedure Write_End_Horizontal_Retrace_Register (Register : End_Horizontal_Retrace_Register) is
      procedure Write is new
        Write_Register (End_Horizontal_Retrace_Register, End_Horizontal_Retrace);
   begin
      Write (Register);
   end Write_End_Horizontal_Retrace_Register;

   function Read_End_Horizontal_Retrace_Register return End_Horizontal_Retrace_Register is
      function Read is new Read_Register (End_Horizontal_Retrace_Register, End_Horizontal_Retrace);
   begin
      return Read;
   end Read_End_Horizontal_Retrace_Register;


   -- Vertical_Total_Register --
   procedure Write_Vertical_Total_Register (Register : Vertical_Total_Register) is
      procedure Write is new Write_Register (Vertical_Total_Register, Vertical_Total);
   begin
      Write (Register);
   end Write_Vertical_Total_Register;

   function Read_Vertical_Total_Register return Vertical_Total_Register is
      function Read is new Read_Register (Vertical_Total_Register, Vertical_Total);
   begin
      return Read;
   end Read_Vertical_Total_Register;


   -- Overflow_Register --
   procedure Write_Overflow_Register (Register : Overflow_Register) is
      procedure Write is new Write_Register (Overflow_Register, Overflow);
   begin
      Write (Register);
   end Write_Overflow_Register;

   function Read_Overflow_Register return Overflow_Register is
      function Read is new Read_Register (Overflow_Register, Overflow);
   begin
      return Read;
   end Read_Overflow_Register;


   -- Preset_Row_Scan_Register --
   procedure Write_Preset_Row_Scan_Register (Register : Preset_Row_Scan_Register) is
      procedure Write is new Write_Register (Preset_Row_Scan_Register, Preset_Row_Scan);
   begin
      Write (Register);
   end Write_Preset_Row_Scan_Register;

   function Read_Preset_Row_Scan_Register return Preset_Row_Scan_Register is
      function Read is new Read_Register (Preset_Row_Scan_Register, Preset_Row_Scan);
   begin
      return Read;
   end Read_Preset_Row_Scan_Register;


   -- Maximum_Scan_Line_Register --
   procedure Write_Maximum_Scan_Line_Register (Register : Maximum_Scan_Line_Register) is
      procedure Write is new Write_Register (Maximum_Scan_Line_Register, Maximum_Scan_Line);
   begin
      Write (Register);
   end Write_Maximum_Scan_Line_Register;

   function Read_Maximum_Scan_Line_Register return Maximum_Scan_Line_Register is
      function Read is new Read_Register (Maximum_Scan_Line_Register, Maximum_Scan_Line);
   begin
      return Read;
   end Read_Maximum_Scan_Line_Register;


   -- Cursor_Start_Register --
   procedure Write_Cursor_Start_Register (Register : Cursor_Start_Register) is
      procedure Write is new Write_Register (Cursor_Start_Register, Cursor_Start);
   begin
      Write (Register);
   end Write_Cursor_Start_Register;

   function Read_Cursor_Start_Register return Cursor_Start_Register is
      function Read is new Read_Register (Cursor_Start_Register, Cursor_Start);
   begin
      return Read;
   end Read_Cursor_Start_Register;


   -- Cursor_End_Register --
   procedure Write_Cursor_End_Register (Register : Cursor_End_Register) is
      procedure Write is new Write_Register (Cursor_End_Register, Cursor_End);
   begin
      Write (Register);
   end Write_Cursor_End_Register;

   function Read_Cursor_End_Register return Cursor_End_Register is
      function Read is new Read_Register (Cursor_End_Register, Cursor_End);
   begin
      return Read;
   end Read_Cursor_End_Register;


   -- Start_Address_High_Register --
   procedure Write_Start_Address_High_Register (Register : Start_Address_High_Register) is
      procedure Write is new Write_Register (Start_Address_High_Register, Start_Address_High);
   begin
      Write (Register);
   end Write_Start_Address_High_Register;

   function Read_Start_Address_High_Register return Start_Address_High_Register is
      function Read is new Read_Register (Start_Address_High_Register, Start_Address_High);
   begin
      return Read;
   end Read_Start_Address_High_Register;


   -- Start_Address_Low_Register --
   procedure Write_Start_Address_Low_Register (Register : Start_Address_Low_Register) is
      procedure Write is new Write_Register (Start_Address_Low_Register, Start_Address_Low);
   begin
      Write (Register);
   end Write_Start_Address_Low_Register;

   function Read_Start_Address_Low_Register return Start_Address_Low_Register is
      function Read is new Read_Register (Start_Address_Low_Register, Start_Address_Low);
   begin
      return Read;
   end Read_Start_Address_Low_Register;


   -- Cursor_Location_High_Register --
   procedure Write_Cursor_Location_High_Register (Register : Cursor_Location_High_Register) is
      procedure Write is new Write_Register (Cursor_Location_High_Register, Cursor_Location_High);
   begin
      Write (Register);
   end Write_Cursor_Location_High_Register;

   function Read_Cursor_Location_High_Register return Cursor_Location_High_Register is
      function Read is new Read_Register (Cursor_Location_High_Register, Cursor_Location_High);
   begin
      return Read;
   end Read_Cursor_Location_High_Register;


   -- Cursor_Location_Low_Register --
   procedure Write_Cursor_Location_Low_Register (Register : Cursor_Location_Low_Register) is
      procedure Write is new Write_Register (Cursor_Location_Low_Register, Cursor_Location_Low);
   begin
      Write (Register);
   end Write_Cursor_Location_Low_Register;

   function Read_Cursor_Location_Low_Register return Cursor_Location_Low_Register is
      function Read is new Read_Register (Cursor_Location_Low_Register, Cursor_Location_Low);
   begin
      return Read;
   end Read_Cursor_Location_Low_Register;


   -- Vertical_Retrace_Start_Register --
   procedure Write_Vertical_Retrace_Start_Register (Register : Vertical_Retrace_Start_Register) is
      procedure Write is new
        Write_Register (Vertical_Retrace_Start_Register, Vertical_Retrace_Start);
   begin
      Write (Register);
   end Write_Vertical_Retrace_Start_Register;

   function Read_Vertical_Retrace_Start_Register return Vertical_Retrace_Start_Register is
      function Read is new Read_Register (Vertical_Retrace_Start_Register, Vertical_Retrace_Start);
   begin
      return Read;
   end Read_Vertical_Retrace_Start_Register;


   -- Vertical_Retrace_End_Register --
   procedure Write_Vertical_Retrace_End_Register (Register : Vertical_Retrace_End_Register) is
      procedure Write is new Write_Register (Vertical_Retrace_End_Register, Vertical_Retrace_End);
   begin
      Write (Register);
   end Write_Vertical_Retrace_End_Register;

   function Read_Vertical_Retrace_End_Register return Vertical_Retrace_End_Register is
      function Read is new Read_Register (Vertical_Retrace_End_Register, Vertical_Retrace_End);
   begin
      return Read;
   end Read_Vertical_Retrace_End_Register;


   -- Vertical_Display_Enable_End_Register --
   procedure Write_Vertical_Display_Enable_End_Register
     (Register : Vertical_Display_Enable_End_Register)
   is
      procedure Write is new
        Write_Register (Vertical_Display_Enable_End_Register, Vertical_Display_Enable_End);
   begin
      Write (Register);
   end Write_Vertical_Display_Enable_End_Register;

   function Read_Vertical_Display_Enable_End_Register return Vertical_Display_Enable_End_Register is
      function Read is new
        Read_Register (Vertical_Display_Enable_End_Register, Vertical_Display_Enable_End);
   begin
      return Read;
   end Read_Vertical_Display_Enable_End_Register;


   -- Offset_Register --
   procedure Write_Offset_Register (Register : Offset_Register) is
      procedure Write is new Write_Register (Offset_Register, Offset);
   begin
      Write (Register);
   end Write_Offset_Register;

   function Read_Offset_Register return Offset_Register is
      function Read is new Read_Register (Offset_Register, Offset);
   begin
      return Read;
   end Read_Offset_Register;


   -- Underline_Location_Register --
   procedure Write_Underline_Location_Register (Register : Underline_Location_Register) is
      procedure Write is new Write_Register (Underline_Location_Register, Underline_Location);
   begin
      Write (Register);
   end Write_Underline_Location_Register;

   function Read_Underline_Location_Register return Underline_Location_Register is
      function Read is new Read_Register (Underline_Location_Register, Underline_Location);
   begin
      return Read;
   end Read_Underline_Location_Register;


   -- Start_Vertical_Blanking_Register --
   procedure Write_Start_Vertical_Blanking_Register (Register : Start_Vertical_Blanking_Register) is
      procedure Write is new
        Write_Register (Start_Vertical_Blanking_Register, Start_Vertical_Blanking);
   begin
      Write (Register);
   end Write_Start_Vertical_Blanking_Register;

   function Read_Start_Vertical_Blanking_Register return Start_Vertical_Blanking_Register is
      function Read is new
        Read_Register (Start_Vertical_Blanking_Register, Start_Vertical_Blanking);
   begin
      return Read;
   end Read_Start_Vertical_Blanking_Register;


   -- End_Vertical_Blanking_Register --
   procedure Write_End_Vertical_Blanking_Register (Register : End_Vertical_Blanking_Register) is
      procedure Write is new Write_Register (End_Vertical_Blanking_Register, End_Vertical_Blanking);
   begin
      Write (Register);
   end Write_End_Vertical_Blanking_Register;

   function Read_End_Vertical_Blanking_Register return End_Vertical_Blanking_Register is
      function Read is new Read_Register (End_Vertical_Blanking_Register, End_Vertical_Blanking);
   begin
      return Read;
   end Read_End_Vertical_Blanking_Register;


   -- CRT_Mode_Control_Register --
   procedure Write_CRT_Mode_Control_Register (Register : CRT_Mode_Control_Register) is
      procedure Write is new Write_Register (CRT_Mode_Control_Register, CRT_Mode_Control);
   begin
      Write (Register);
   end Write_CRT_Mode_Control_Register;

   function Read_CRT_Mode_Control_Register return CRT_Mode_Control_Register is
      function Read is new Read_Register (CRT_Mode_Control_Register, CRT_Mode_Control);
   begin
      return Read;
   end Read_CRT_Mode_Control_Register;


   -- Line_Compare_Register --
   procedure Write_Line_Compare_Register (Register : Line_Compare_Register) is
      procedure Write is new Write_Register (Line_Compare_Register, Line_Compare);
   begin
      Write (Register);
   end Write_Line_Compare_Register;

   function Read_Line_Compare_Register return Line_Compare_Register is
      function Read is new Read_Register (Line_Compare_Register, Line_Compare);
   begin
      return Read;
   end Read_Line_Compare_Register;



end VGA.CRTC;
