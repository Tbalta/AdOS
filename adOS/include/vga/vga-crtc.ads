with System;
with x86.Port_IO;
package VGA.CRTC is
   pragma Pure;

   --------------------
   -- Horizontal_Total_Register --
   --------------------
   type Horizontal_Total_Register is new Unsigned_8;
   for Horizontal_Total_Register'Size use 8;
   procedure Write_Horizontal_Total_Register (Register : Horizontal_Total_Register);
   function  Read_Horizontal_Total_Register return Horizontal_Total_Register;

   --------------------
   -- Horizontal_Display_Enable_End_Register --
   --------------------
   type Horizontal_Display_Enable_End_Register is new Unsigned_8;
   for Horizontal_Display_Enable_End_Register'Size use 8;
   procedure Write_Horizontal_Display_Enable_End_Register (Register : Horizontal_Display_Enable_End_Register);
   function  Read_Horizontal_Display_Enable_End_Register return Horizontal_Display_Enable_End_Register;

   --------------------
   -- Start_Horizontal_Blanking_Register --
   --------------------
   type Start_Horizontal_Blanking_Register is new Unsigned_8;
   for Start_Horizontal_Blanking_Register'Size use 8;
   procedure Write_Start_Horizontal_Blanking_Register (Register : Start_Horizontal_Blanking_Register);
   function  Read_Start_Horizontal_Blanking_Register return Start_Horizontal_Blanking_Register;

   --------------------
   -- End_Horizontal_Blanking_Register --
   --------------------
   type End_Horizontal_Blanking_Register is record
      End_Blanking : Unsigned_8;
      Display_Enable_Skew : Unsigned_8;
   end record
      with Size => 8;
   for End_Horizontal_Blanking_Register use record
      End_Blanking at 0 range 0 .. 4;
      Display_Enable_Skew at 0 range 5 .. 6;
   end record;
   for End_Horizontal_Blanking_Register'Size use 8;
   procedure Write_End_Horizontal_Blanking_Register (Register : End_Horizontal_Blanking_Register);
   function  Read_End_Horizontal_Blanking_Register return End_Horizontal_Blanking_Register;


   --------------------
   -- Start_Horizontal_Retrace_Pulse_Register --
   --------------------
   type Start_Horizontal_Retrace_Pulse_Register is new Unsigned_8;
   for Start_Horizontal_Retrace_Pulse_Register'Size use 8;
   procedure Write_Start_Horizontal_Retrace_Pulse_Register (Register : Start_Horizontal_Retrace_Pulse_Register);
   function  Read_Start_Horizontal_Retrace_Pulse_Register return Start_Horizontal_Retrace_Pulse_Register;

   --------------------
   -- End_Horizontal_Retrace_Register --
   --------------------
   type End_Horizontal_Retrace_Register is record
       EHR : Unsigned_8;
       HRD : Unsigned_8;
       EB5 : Unsigned_8;
   end record
      with Size => 8;
   for End_Horizontal_Retrace_Register use record
      EHR at 0 range 0 .. 4;
      HRD at 0 range 5 .. 6;
      EB5 at 0 range 7 .. 7;
   end record;
   for End_Horizontal_Retrace_Register'Size use 8;
   procedure Write_End_Horizontal_Retrace_Register (Register : End_Horizontal_Retrace_Register);
   function  Read_End_Horizontal_Retrace_Register return End_Horizontal_Retrace_Register;
   

   --------------------
   -- Vertical_Total_Register --
   --------------------
   type Vertical_Total_Register is new Unsigned_8;
   for Vertical_Total_Register'Size use 8;
   procedure Write_Vertical_Total_Register (Register : Vertical_Total_Register);
   function  Read_Vertical_Total_Register return Vertical_Total_Register;


   --------------------
   -- Overflow_Register --
   --------------------
   type Overflow_Register is record
       VT8 : Unsigned_8;
       VDE8 : Unsigned_8;
       VRS8 : Unsigned_8;
       VBS8 : Unsigned_8;
       LC8 : Unsigned_8;
       VT9 : Unsigned_8;
       VDE9 : Unsigned_8;
       VRS9 : Unsigned_8;
   end record
      with Size => 8;
   for Overflow_Register use record
       VT8 at 0 range 0 .. 0;
       VDE8 at 0 range 1 .. 1;
       VRS8 at 0 range 2 .. 2;
       VBS8 at 0 range 3 .. 3;
       LC8 at 0 range 4 .. 4;
       VT9 at 0 range 5 .. 5;
       VDE9 at 0 range 6 .. 6;
       VRS9 at 0 range 7 .. 7;
   end record;
   for Overflow_Register'Size use 8;
   procedure Write_Overflow_Register (Register : Overflow_Register);
   function  Read_Overflow_Register return Overflow_Register;

   --------------------
   -- Preset_Row_Scan_Register --
   --------------------
   type Preset_Row_Scan_Register is record
       Starting_Row_Scan_Count : Unsigned_8;
       Byte_Panning : Unsigned_8;
   end record
      with Size => 8;
   for Preset_Row_Scan_Register use record
       Starting_Row_Scan_Count at 0 range 0 .. 4;
       Byte_Panning at 0 range 5 .. 6;
   end record;
   procedure Write_Preset_Row_Scan_Register (Register : Preset_Row_Scan_Register);
   function  Read_Preset_Row_Scan_Register return Preset_Row_Scan_Register;

   --------------------
   -- Maxixum_Scan_Line_Register --
   --------------------
   type Maxixum_Scan_Line_Register is record
       MSL  : Unsigned_8;
       VBS9 : Unsigned_8;
       LC9 : Unsigned_8;
       Double_Scanning : Boolean;
   end record
      with Size => 8;
   for Maxixum_Scan_Line_Register use record
       MSL  at 0 range 0 .. 4;
       VBS9 at 0 range 5 .. 5;
       LC9 at 0 range 6 .. 6;
       Double_Scanning at 0 range 7 .. 7;
   end record;
   procedure Write_Maxixum_Scan_Line_Register (Register : Maxixum_Scan_Line_Register);
   function  Read_Maxixum_Scan_Line_Register return Maxixum_Scan_Line_Register;

   --------------------
   -- Cursor_Start_Register --
   --------------------
   type Cursor_Start_Register is record
       Row_Scan_Cursor_Begins  : Unsigned_8;
       Cursor_Off : Boolean;
   end record
      with Size => 8;
   for Cursor_Start_Register use record
       Row_Scan_Cursor_Begins  at 0 range 0 .. 4;
       Cursor_Off at 0 range 5 .. 5;
   end record;
   procedure Write_Cursor_Start_Register (Register : Cursor_Start_Register);
   function  Read_Cursor_Start_Register return Cursor_Start_Register;

   --------------------
   -- Cursor_End_Register --
   --------------------
   type Cursor_End_Register is record
       Row_Scan_Cursor_Ends  : Unsigned_8;
       Cursor_Skew_Control : Unsigned_8;
   end record
      with Size => 8;
   for Cursor_End_Register use record
       Row_Scan_Cursor_Ends  at 0 range 0 .. 4;
       Cursor_Skew_Control at 0 range 5 .. 6;
   end record;
   procedure Write_Cursor_End_Register (Register : Cursor_End_Register);
   function  Read_Cursor_End_Register return Cursor_End_Register;


      --------------------
   -- Start_Address_High_Register --
   --------------------
   type Start_Address_High_Register is new Unsigned_8;
   for Start_Address_High_Register'Size use 8;
   procedure Write_Start_Address_High_Register (Register : Start_Address_High_Register);
   function  Read_Start_Address_High_Register return Start_Address_High_Register;

      --------------------
   -- Start_Address_Low_Register --
   --------------------
   type Start_Address_Low_Register is new Unsigned_8;
   for Start_Address_Low_Register'Size use 8;
   procedure Write_Start_Address_Low_Register (Register : Start_Address_Low_Register);
   function  Read_Start_Address_Low_Register return Start_Address_Low_Register;

      --------------------
   -- Cursor_Location_High_Register --
   --------------------
   type Cursor_Location_High_Register is new Unsigned_8;
   for Cursor_Location_High_Register'Size use 8;
   procedure Write_Cursor_Location_High_Register (Register : Cursor_Location_High_Register);
   function  Read_Cursor_Location_High_Register return Cursor_Location_High_Register;

      --------------------
   -- Cursor_Location_Low_Register --
   --------------------
   type Cursor_Location_Low_Register is new Unsigned_8;
   for Cursor_Location_Low_Register'Size use 8;
   procedure Write_Cursor_Location_Low_Register (Register : Cursor_Location_Low_Register);
   function  Read_Cursor_Location_Low_Register return Cursor_Location_Low_Register;

      --------------------
   -- Vertical_Retrace_Start_Register --
   --------------------
   type Vertical_Retrace_Start_Register is new Unsigned_8;
   for Vertical_Retrace_Start_Register'Size use 8;
   procedure Write_Vertical_Retrace_Start_Register (Register : Vertical_Retrace_Start_Register);
   function  Read_Vertical_Retrace_Start_Register return Vertical_Retrace_Start_Register;

   --------------------
   -- Vertical_Retrace_End_Register --
   --------------------
   type Vertical_Retrace_End_Register is record
       VRE  : Unsigned_8;
       Clear_Vertical_Interrupt : Boolean;
       Enable_Vertical_Interrupt : Boolean;
       Select_5_Refresh_Cycles : Unsigned_8;
       Protect_Register : Boolean;
   end record
      with Size => 8;
   for Vertical_Retrace_End_Register use record
       VRE  at 0 range 0 .. 3;
       Clear_Vertical_Interrupt at 0 range 4 .. 4 ;
       Enable_Vertical_Interrupt at 0 range 5 .. 5 ;
       Select_5_Refresh_Cycles at 0 range 6 .. 6 ;
       Protect_Register at 0 range 7 .. 7 ;
   end record;
   procedure Write_Vertical_Retrace_End_Register (Register : Vertical_Retrace_End_Register);
   function  Read_Vertical_Retrace_End_Register return Vertical_Retrace_End_Register;

         --------------------
   -- Vertical_Display_Enable_End --
   --------------------
   type Vertical_Display_Enable_End is new Unsigned_8;
   for Vertical_Display_Enable_End'Size use 8;
   procedure Write_Vertical_Display_Enable_End (Register : Vertical_Display_Enable_End);
   function  Read_Vertical_Display_Enable_End return Vertical_Display_Enable_End;

         --------------------
   -- Offset_Register --
   --------------------
   type Offset_Register is new Unsigned_8;
   for Offset_Register'Size use 8;
   procedure Write_Offset_Register (Register : Offset_Register);
   function  Read_Offset_Register return Offset_Register;

      --------------------
   -- Underline_Location_Register --
   --------------------
   type Underline_Location_Register is record
       Start_Under_Line  : Unsigned_8;
       Count_By_4 : Boolean;
       Double_Word : Boolean;
   end record
      with Size => 8;
   for Underline_Location_Register use record
       Start_Under_Line  at 0 range 0 .. 4;
       Count_By_4 at 0 range 5 .. 5;
       Double_Word at 0 range 6 .. 6;
   end record;
   procedure Write_Underline_Location_Register (Register : Underline_Location_Register);
   function  Read_Underline_Location_Register return Underline_Location_Register;


         --------------------
   -- Start_Vertical_Blanking_Register --
   --------------------
   type Start_Vertical_Blanking_Register is new Unsigned_8;
   for Start_Vertical_Blanking_Register'Size use 8;
   procedure Write_Start_Vertical_Blanking_Register (Register : Start_Vertical_Blanking_Register);
   function  Read_Start_Vertical_Blanking_Register return Start_Vertical_Blanking_Register;

            --------------------
   -- End_Vertical_Blanking_Register --
   --------------------
   type End_Vertical_Blanking_Register is new Unsigned_8;
   for End_Vertical_Blanking_Register'Size use 8;
   procedure Write_End_Vertical_Blanking_Register (Register : End_Vertical_Blanking_Register);
   function  Read_End_Vertical_Blanking_Register return End_Vertical_Blanking_Register;
   
         --------------------
   -- CRT_Mode_Control_Register --
   --------------------
   type CRT_Mode_Control_Register is record
       CSM_0  : Boolean;
       SRC  : Boolean;
       HRS  : Boolean;
       Count_By_2  : Boolean;
       Address_Wrap  : Boolean;
       Word_Byte_Mode : Boolean;
       Hardware_Reset  : Boolean;
   end record
      with Size => 8;
   for CRT_Mode_Control_Register use record
      CSM_0  at 0 range 0 .. 0;
       SRC  at 0 range 1 .. 1;
       HRS  at 0 range 2 .. 2;
       Count_By_2  at 0 range 3 .. 3;
       Address_Wrap  at 0 range 5 .. 5;
       Word_Byte_Mode at 0 range 6 .. 6;
       Hardware_Reset  at 0 range 7 .. 7;
   end record;
   procedure Write_CRT_Mode_Control_Register (Register : CRT_Mode_Control_Register);
   function  Read_CRT_Mode_Control_Register return CRT_Mode_Control_Register;

            --------------------
   -- Line_Compare_register --
   --------------------
   type Line_Compare_register is new Unsigned_8;
   for Line_Compare_register'Size use 8;
   procedure Write_Line_Compare_register (Register : Line_Compare_register);
   function  Read_Line_Compare_register return Line_Compare_register;

private
   Address_Register_Address : System.Address := 16#03C4#;
   Data_Register_Address    : System.Address := 16#03C5#;
   type CRTC_Registers is (
      Horizontal_Total,
      Horizontal_Display_Enable_End,
      Start_Horizontal_Blanking,
      End_Horizontal_Blanking,
      Start_Horizontal_Retrace_Pulse,
      End_Horizontal_Retrace,
      Vertical_Total,
      Overflow,
      Preset_Row_Scan,
      Maximum_Scan_Line,
      Cursor_Start,
      Cursor_End,
      Start_Address_High,
      Start_Address_Low,
      Cursor_Location_High,
      Cursor_Location_Low,
      Vertical_Retrace_Start,
      Vertical_Retrace_End,
      Vertical_Display_Enable_End,
      Offset_Underline_Location,
      Start_Vertical_Blanking,
      End_Vertical_Blanking,
      CRT_Mode_Control,
      Line_Compare
);
   for CRTC_Registers use (
      Horizontal_Total               => 16#00#,
      Horizontal_Display_Enable_End  => 16#01#,
      Start_Horizontal_Blanking      => 16#02#,
      End_Horizontal_Blanking        => 16#03#,
      Start_Horizontal_Retrace_Pulse => 16#04#,
      End_Horizontal_Retrace         => 16#05#,
      Vertical_Total                 => 16#06#,
      Overflow                       => 16#07#,
      Preset_Row_Scan                => 16#08#,
      Maximum_Scan_Line              => 16#09#,
      Cursor_Start                   => 16#0A#,
      Cursor_End                     => 16#0B#,
      Start_Address_High             => 16#0C#,
      Start_Address_Low              => 16#0D#,
      Cursor_Location_High           => 16#0E#,
      Cursor_Location_Low            => 16#0F#,
      Vertical_Retrace_Start         => 16#10#,
      Vertical_Retrace_End           => 16#11#,
      Vertical_Display_Enable_End    => 16#12#,
      Offset                         => 16#13#,
      Underline_Location             => 16#14#,
      Start_Vertical_Blanking        => 16#15#,
      End_Vertical_Blanking          => 16#16#,
      CRT_Mode_Control               => 16#17#,
      Line_Compare                   => 16#18#
   );
   for CRTC_Registers'Address use 8;
   
   procedure Write_Address is new x86.Port_IO.Write_Port_8 (Address_Register_Address, Sequencer_Registers);

   generic
      type Data_Type is private;
      Index : Sequencer_Registers;
   procedure Write_Data (Value : Data_Type);
   generic
      type Data_Type is private;
      Index : Sequencer_Registers;
   function Read_Data return Data_Type;



end VGA.CRTC;