with System;
with x86.Port_IO;
with Interfaces; use Interfaces;
package VGA.CRTC is
   pragma Pure;
   -----------------------
   -- Blanking_Register --
   -----------------------
   type bit is range 0 .. 1;
   for bit'Size use 1;
   subtype End_Horizontal_Blanking_LSB is Unsigned_5;
   subtype End_Horizontal_Blanking_MSB is bit;
   type End_Horizontal_Blanking_Value (Bit_Access : Boolean) is record
      case Bit_Access is
         When True =>
            LSB : End_Horizontal_Blanking_LSB;
            MSB : End_Horizontal_Blanking_MSB;
         when False =>
            Value : Unsigned_6;
         end case;
      end record;
   pragma Unchecked_Union (End_Horizontal_Blanking_Value);

   subtype Vertical_Total_LSB is Unsigned_8;
   subtype Vertical_Total_BT8 is bit;
   subtype Vertical_Total_BT9 is bit;
   type Vertical_Total_Value (Bit_Access : Boolean) is record
      case Bit_Access is
         when True =>
            LSB : Vertical_Total_LSB;
            BT8 : Vertical_Total_BT8;
            BT9 : Vertical_Total_BT9;
         when False =>
            Value : Unsigned_10;
         end case;
      end record
         with Size => 10;
   pragma Unchecked_Union (Vertical_Total_Value);
   for Vertical_Total_Value use record
      LSB at 0 range 0 .. 7;
      BT8 at 0 range 8 .. 8;
      BT9 at 0 range 9 .. 9;
      Value at 0 range 0 .. 9;
   end record;

   subtype Vertical_Display_Enable_End_BT9 is bit;
   subtype Vertical_Display_Enable_End_BT8 is bit;

   subtype Vertical_Retrace_Start_BT9 is bit;
   subtype Vertical_Retrace_Start_BT8 is bit;

    subtype Line_Compare_BT8 is bit;
    subtype Line_Compare_BT9 is bit;


    subtype Vertical_Blanking_Start_BT8 is bit;
    subtype Vertical_Blanking_Start_BT9 is bit;
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
   type Skew_Amount is range 0 .. 3;
   type End_Horizontal_Blanking_Register is record
      End_Blanking : End_Horizontal_Blanking_LSB;
      Display_Enable_Skew : Skew_Amount;
      one                 : bit := 1;
   end record
      with Size => 8;
   for End_Horizontal_Blanking_Register use record
      End_Blanking at 0 range 0 .. 4;
      Display_Enable_Skew at 0 range 5 .. 6;
      one at 0 range 7 .. 7;
   end record;
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
       EHR : Unsigned_5;
       HRD : Unsigned_2;
       EB5 : End_Horizontal_Blanking_MSB;
   end record
      with Size => 8;
   for End_Horizontal_Retrace_Register use record
      EHR at 0 range 0 .. 4;
      HRD at 0 range 5 .. 6;
      EB5 at 0 range 7 .. 7;
   end record;
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
       VT8 : Vertical_Total_BT8;
       VDE8 : Vertical_Display_Enable_End_BT8;
       VRS8 : Vertical_Retrace_Start_BT8;
       VBS8 : Vertical_Blanking_Start_BT8;
       LC8 : Line_Compare_BT8;
       VT9 : Vertical_Total_BT9;
       VDE9 : Vertical_Display_Enable_End_BT9;
       VRS9 : Vertical_Retrace_Start_BT9;
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
   procedure Write_Overflow_Register (Register : Overflow_Register);
   function  Read_Overflow_Register return Overflow_Register;

   --------------------
   -- Preset_Row_Scan_Register --
   --------------------
   type Preset_Row_Scan_Register is record
       Starting_Row_Scan_Count : Unsigned_5;
       Byte_Panning : Unsigned_2;
       unused : bit := 0;
   end record
      with Size => 8;
   for Preset_Row_Scan_Register use record
       Starting_Row_Scan_Count at 0 range 0 .. 4;
       Byte_Panning at 0 range 5 .. 6;
       unused at 0 range 7 .. 7;
   end record;
   procedure Write_Preset_Row_Scan_Register (Register : Preset_Row_Scan_Register);
   function  Read_Preset_Row_Scan_Register return Preset_Row_Scan_Register;

   --------------------
   -- Maximum_Scan_Line_Register --
   --------------------
   type Maximum_Scan_Line_Register is record
       MSL  : Unsigned_5;
       VBS9 : Vertical_Blanking_Start_BT9;
       LC9 : Line_Compare_BT9;
       Double_Scanning : Boolean;
   end record
      with Size => 8;
   for Maximum_Scan_Line_Register use record
       MSL  at 0 range 0 .. 4;
       VBS9 at 0 range 5 .. 5;
       LC9 at 0 range 6 .. 6;
       Double_Scanning at 0 range 7 .. 7;
   end record;
   procedure Write_Maximum_Scan_Line_Register (Register : Maximum_Scan_Line_Register);
   function  Read_Maximum_Scan_Line_Register return Maximum_Scan_Line_Register;

   --------------------
   -- Cursor_Start_Register --
   --------------------
   type Cursor_Start_Register is record
       Row_Scan_Cursor_Begins  : Unsigned_5;
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
       Row_Scan_Cursor_Ends  : Unsigned_5;
       Cursor_Skew_Control : Unsigned_2;
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
       VRE  : Unsigned_4;
       Clear_Vertical_Interrupt : Boolean;
       Enable_Vertical_Interrupt : Boolean;
       Select_5_Refresh_Cycles : Boolean;
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
   -- Vertical_Display_Enable_End_Register --
   --------------------
   type Vertical_Display_Enable_End_Register is new Unsigned_8;
   for Vertical_Display_Enable_End_Register'Size use 8;
   procedure Write_Vertical_Display_Enable_End_Register (Register : Vertical_Display_Enable_End_Register);
   function  Read_Vertical_Display_Enable_End_Register return Vertical_Display_Enable_End_Register;

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
       Start_Under_Line  : Unsigned_5;
       Count_By_4 : Boolean;
       Double_Word : Boolean;
       unused : bit := 0;
   end record
      with Size => 8;
   for Underline_Location_Register use record
       Start_Under_Line  at 0 range 0 .. 4;
       Count_By_4 at 0 range 5 .. 5;
       Double_Word at 0 range 6 .. 6;
       unused at 0 range 7 .. 7;
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
   Address_Register_Address : constant System.Address := 16#03D4#;
   Data_Register_Address    : constant System.Address := 16#03D5#;
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
      Offset,
      Underline_Location,
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
   for CRTC_Registers'Size use 8;
   
   procedure Write_Address is new x86.Port_IO.Write_Port_8 (Address_Register_Address, CRTC_Registers);

   generic
      type Data_Type is private;
      Index : CRTC_Registers;
   procedure Write_Data (Value : Data_Type);
   generic
      type Data_Type is private;
      Index : CRTC_Registers;
   function Read_Data return Data_Type;



end VGA.CRTC;