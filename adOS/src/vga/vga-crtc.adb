with VGA.CRTC;
with x86.Port_Io;
with Ada.Unchecked_Conversion;
with SERIAL;
with Interfaces; use Interfaces;
package body VGA.CRTC is

   procedure Write_Data (Value : Data_Type)
   is
      procedure Write is new x86.Port_IO.Write_Port_8 (Data_Register_Address, Data_Type);
      function To_U8 is new Ada.Unchecked_Conversion (Target => Unsigned_8, Source => Data_Type);
   begin
      Write_Address (Index);
      Write (Value);
      SERIAL.send_string (Value'Image & "| is ");
      SERIAL.send_hex (Unsigned_32 (To_U8 (Value)));
      SERIAL.send_line("");
   end Write_Data;

   function Read_Data return Data_Type
   is
      function Read is new x86.Port_IO.Read_Port_8 (Data_Register_Address, Data_Type);
   begin
      Write_Address (Index);
      return Read;
   end Read_Data;


   -- Horizontal_Total_Register --
procedure Write_Horizontal_Total_Register (Register : Horizontal_Total_Register)
is
   procedure Write is new Write_Data (Horizontal_Total_Register, Horizontal_Total);
   begin
   Write (Register);
end Write_Horizontal_Total_Register;

function Read_Horizontal_Total_Register return Horizontal_Total_Register
is 
   function Read is new Read_Data (Horizontal_Total_Register, Horizontal_Total);
begin
   return Read;
end Read_Horizontal_Total_Register;


   -- Horizontal_Display_Enable_End_Register --
procedure Write_Horizontal_Display_Enable_End_Register (Register : Horizontal_Display_Enable_End_Register)
is
   procedure Write is new Write_Data (Horizontal_Display_Enable_End_Register, Horizontal_Display_Enable_End);
   begin
   Write (Register);
end Write_Horizontal_Display_Enable_End_Register;

function Read_Horizontal_Display_Enable_End_Register return Horizontal_Display_Enable_End_Register
is 
   function Read is new Read_Data (Horizontal_Display_Enable_End_Register, Horizontal_Display_Enable_End);
begin
   return Read;
end Read_Horizontal_Display_Enable_End_Register;


   -- Start_Horizontal_Blanking_Register --
procedure Write_Start_Horizontal_Blanking_Register (Register : Start_Horizontal_Blanking_Register)
is
   procedure Write is new Write_Data (Start_Horizontal_Blanking_Register, Start_Horizontal_Blanking);
   begin
   Write (Register);
end Write_Start_Horizontal_Blanking_Register;

function Read_Start_Horizontal_Blanking_Register return Start_Horizontal_Blanking_Register
is 
   function Read is new Read_Data (Start_Horizontal_Blanking_Register, Start_Horizontal_Blanking);
begin
   return Read;
end Read_Start_Horizontal_Blanking_Register;


   -- End_Horizontal_Blanking_Register --
procedure Write_End_Horizontal_Blanking_Register (Register : End_Horizontal_Blanking_Register)
is
   procedure Write is new Write_Data (End_Horizontal_Blanking_Register, End_Horizontal_Blanking);
   begin
   Write (Register);
end Write_End_Horizontal_Blanking_Register;

function Read_End_Horizontal_Blanking_Register return End_Horizontal_Blanking_Register
is 
   function Read is new Read_Data (End_Horizontal_Blanking_Register, End_Horizontal_Blanking);
begin
   return Read;
end Read_End_Horizontal_Blanking_Register;


   -- Start_Horizontal_Retrace_Pulse_Register --
procedure Write_Start_Horizontal_Retrace_Pulse_Register (Register : Start_Horizontal_Retrace_Pulse_Register)
is
   procedure Write is new Write_Data (Start_Horizontal_Retrace_Pulse_Register, Start_Horizontal_Retrace_Pulse);
   begin
   Write (Register);
end Write_Start_Horizontal_Retrace_Pulse_Register;

function Read_Start_Horizontal_Retrace_Pulse_Register return Start_Horizontal_Retrace_Pulse_Register
is 
   function Read is new Read_Data (Start_Horizontal_Retrace_Pulse_Register, Start_Horizontal_Retrace_Pulse);
begin
   return Read;
end Read_Start_Horizontal_Retrace_Pulse_Register;


   -- End_Horizontal_Retrace_Register --
procedure Write_End_Horizontal_Retrace_Register (Register : End_Horizontal_Retrace_Register)
is
   procedure Write is new Write_Data (End_Horizontal_Retrace_Register, End_Horizontal_Retrace);
   begin
   Write (Register);
end Write_End_Horizontal_Retrace_Register;

function Read_End_Horizontal_Retrace_Register return End_Horizontal_Retrace_Register
is 
   function Read is new Read_Data (End_Horizontal_Retrace_Register, End_Horizontal_Retrace);
begin
   return Read;
end Read_End_Horizontal_Retrace_Register;


   -- Vertical_Total_Register --
procedure Write_Vertical_Total_Register (Register : Vertical_Total_Register)
is
   procedure Write is new Write_Data (Vertical_Total_Register, Vertical_Total);
   begin
   Write (Register);
end Write_Vertical_Total_Register;

function Read_Vertical_Total_Register return Vertical_Total_Register
is 
   function Read is new Read_Data (Vertical_Total_Register, Vertical_Total);
begin
   return Read;
end Read_Vertical_Total_Register;


   -- Overflow_Register --
procedure Write_Overflow_Register (Register : Overflow_Register)
is
   procedure Write is new Write_Data (Overflow_Register, Overflow);
   begin
   Write (Register);
end Write_Overflow_Register;

function Read_Overflow_Register return Overflow_Register
is 
   function Read is new Read_Data (Overflow_Register, Overflow);
begin
   return Read;
end Read_Overflow_Register;


   -- Preset_Row_Scan_Register --
procedure Write_Preset_Row_Scan_Register (Register : Preset_Row_Scan_Register)
is
   procedure Write is new Write_Data (Preset_Row_Scan_Register, Preset_Row_Scan);
   begin
   Write (Register);
end Write_Preset_Row_Scan_Register;

function Read_Preset_Row_Scan_Register return Preset_Row_Scan_Register
is 
   function Read is new Read_Data (Preset_Row_Scan_Register, Preset_Row_Scan);
begin
   return Read;
end Read_Preset_Row_Scan_Register;


   -- Maximum_Scan_Line_Register --
procedure Write_Maximum_Scan_Line_Register (Register : Maximum_Scan_Line_Register)
is
   procedure Write is new Write_Data (Maximum_Scan_Line_Register, Maximum_Scan_Line);
   begin
   Write (Register);
end Write_Maximum_Scan_Line_Register;

function Read_Maximum_Scan_Line_Register return Maximum_Scan_Line_Register
is 
   function Read is new Read_Data (Maximum_Scan_Line_Register, Maximum_Scan_Line);
begin
   return Read;
end Read_Maximum_Scan_Line_Register;


   -- Cursor_Start_Register --
procedure Write_Cursor_Start_Register (Register : Cursor_Start_Register)
is
   procedure Write is new Write_Data (Cursor_Start_Register, Cursor_Start);
   begin
   Write (Register);
end Write_Cursor_Start_Register;

function Read_Cursor_Start_Register return Cursor_Start_Register
is 
   function Read is new Read_Data (Cursor_Start_Register, Cursor_Start);
begin
   return Read;
end Read_Cursor_Start_Register;


   -- Cursor_End_Register --
procedure Write_Cursor_End_Register (Register : Cursor_End_Register)
is
   procedure Write is new Write_Data (Cursor_End_Register, Cursor_End);
   begin
   Write (Register);
end Write_Cursor_End_Register;

function Read_Cursor_End_Register return Cursor_End_Register
is 
   function Read is new Read_Data (Cursor_End_Register, Cursor_End);
begin
   return Read;
end Read_Cursor_End_Register;


   -- Start_Address_High_Register --
procedure Write_Start_Address_High_Register (Register : Start_Address_High_Register)
is
   procedure Write is new Write_Data (Start_Address_High_Register, Start_Address_High);
   begin
   Write (Register);
end Write_Start_Address_High_Register;

function Read_Start_Address_High_Register return Start_Address_High_Register
is 
   function Read is new Read_Data (Start_Address_High_Register, Start_Address_High);
begin
   return Read;
end Read_Start_Address_High_Register;


   -- Start_Address_Low_Register --
procedure Write_Start_Address_Low_Register (Register : Start_Address_Low_Register)
is
   procedure Write is new Write_Data (Start_Address_Low_Register, Start_Address_Low);
   begin
   Write (Register);
end Write_Start_Address_Low_Register;

function Read_Start_Address_Low_Register return Start_Address_Low_Register
is 
   function Read is new Read_Data (Start_Address_Low_Register, Start_Address_Low);
begin
   return Read;
end Read_Start_Address_Low_Register;


   -- Cursor_Location_High_Register --
procedure Write_Cursor_Location_High_Register (Register : Cursor_Location_High_Register)
is
   procedure Write is new Write_Data (Cursor_Location_High_Register, Cursor_Location_High);
   begin
   Write (Register);
end Write_Cursor_Location_High_Register;

function Read_Cursor_Location_High_Register return Cursor_Location_High_Register
is 
   function Read is new Read_Data (Cursor_Location_High_Register, Cursor_Location_High);
begin
   return Read;
end Read_Cursor_Location_High_Register;


   -- Cursor_Location_Low_Register --
procedure Write_Cursor_Location_Low_Register (Register : Cursor_Location_Low_Register)
is
   procedure Write is new Write_Data (Cursor_Location_Low_Register, Cursor_Location_Low);
   begin
   Write (Register);
end Write_Cursor_Location_Low_Register;

function Read_Cursor_Location_Low_Register return Cursor_Location_Low_Register
is 
   function Read is new Read_Data (Cursor_Location_Low_Register, Cursor_Location_Low);
begin
   return Read;
end Read_Cursor_Location_Low_Register;


   -- Vertical_Retrace_Start_Register --
procedure Write_Vertical_Retrace_Start_Register (Register : Vertical_Retrace_Start_Register)
is
   procedure Write is new Write_Data (Vertical_Retrace_Start_Register, Vertical_Retrace_Start);
   begin
   Write (Register);
end Write_Vertical_Retrace_Start_Register;

function Read_Vertical_Retrace_Start_Register return Vertical_Retrace_Start_Register
is 
   function Read is new Read_Data (Vertical_Retrace_Start_Register, Vertical_Retrace_Start);
begin
   return Read;
end Read_Vertical_Retrace_Start_Register;


   -- Vertical_Retrace_End_Register --
procedure Write_Vertical_Retrace_End_Register (Register : Vertical_Retrace_End_Register)
is
   procedure Write is new Write_Data (Vertical_Retrace_End_Register, Vertical_Retrace_End);
   begin
   Write (Register);
end Write_Vertical_Retrace_End_Register;

function Read_Vertical_Retrace_End_Register return Vertical_Retrace_End_Register
is 
   function Read is new Read_Data (Vertical_Retrace_End_Register, Vertical_Retrace_End);
begin
   return Read;
end Read_Vertical_Retrace_End_Register;


   -- Vertical_Display_Enable_End_Register --
procedure Write_Vertical_Display_Enable_End_Register (Register : Vertical_Display_Enable_End_Register)
is
   procedure Write is new Write_Data (Vertical_Display_Enable_End_Register, Vertical_Display_Enable_End);
   begin
   Write (Register);
end Write_Vertical_Display_Enable_End_Register;

function Read_Vertical_Display_Enable_End_Register return Vertical_Display_Enable_End_Register
is 
   function Read is new Read_Data (Vertical_Display_Enable_End_Register, Vertical_Display_Enable_End);
begin
   return Read;
end Read_Vertical_Display_Enable_End_Register;


   -- Offset_Register --
procedure Write_Offset_Register (Register : Offset_Register)
is
   procedure Write is new Write_Data (Offset_Register, Offset);
   begin
   Write (Register);
end Write_Offset_Register;

function Read_Offset_Register return Offset_Register
is 
   function Read is new Read_Data (Offset_Register, Offset);
begin
   return Read;
end Read_Offset_Register;


   -- Underline_Location_Register --
procedure Write_Underline_Location_Register (Register : Underline_Location_Register)
is
   procedure Write is new Write_Data (Underline_Location_Register, Underline_Location);
   begin
   Write (Register);
end Write_Underline_Location_Register;

function Read_Underline_Location_Register return Underline_Location_Register
is 
   function Read is new Read_Data (Underline_Location_Register, Underline_Location);
begin
   return Read;
end Read_Underline_Location_Register;


   -- Start_Vertical_Blanking_Register --
procedure Write_Start_Vertical_Blanking_Register (Register : Start_Vertical_Blanking_Register)
is
   procedure Write is new Write_Data (Start_Vertical_Blanking_Register, Start_Vertical_Blanking);
   begin
   Write (Register);
end Write_Start_Vertical_Blanking_Register;

function Read_Start_Vertical_Blanking_Register return Start_Vertical_Blanking_Register
is 
   function Read is new Read_Data (Start_Vertical_Blanking_Register, Start_Vertical_Blanking);
begin
   return Read;
end Read_Start_Vertical_Blanking_Register;


   -- End_Vertical_Blanking_Register --
procedure Write_End_Vertical_Blanking_Register (Register : End_Vertical_Blanking_Register)
is
   procedure Write is new Write_Data (End_Vertical_Blanking_Register, End_Vertical_Blanking);
   begin
   Write (Register);
end Write_End_Vertical_Blanking_Register;

function Read_End_Vertical_Blanking_Register return End_Vertical_Blanking_Register
is 
   function Read is new Read_Data (End_Vertical_Blanking_Register, End_Vertical_Blanking);
begin
   return Read;
end Read_End_Vertical_Blanking_Register;


   -- CRT_Mode_Control_Register --
procedure Write_CRT_Mode_Control_Register (Register : CRT_Mode_Control_Register)
is
   procedure Write is new Write_Data (CRT_Mode_Control_Register, CRT_Mode_Control);
   begin
   Write (Register);
end Write_CRT_Mode_Control_Register;

function Read_CRT_Mode_Control_Register return CRT_Mode_Control_Register
is 
   function Read is new Read_Data (CRT_Mode_Control_Register, CRT_Mode_Control);
begin
   return Read;
end Read_CRT_Mode_Control_Register;


   -- Line_Compare_Register --
procedure Write_Line_Compare_Register (Register : Line_Compare_Register)
is
   procedure Write is new Write_Data (Line_Compare_Register, Line_Compare);
   begin
   Write (Register);
end Write_Line_Compare_Register;

function Read_Line_Compare_Register return Line_Compare_Register
is 
   function Read is new Read_Data (Line_Compare_Register, Line_Compare);
begin
   return Read;
end Read_Line_Compare_Register;



end VGA.CRTC;