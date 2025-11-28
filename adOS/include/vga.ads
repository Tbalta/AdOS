package VGA is
   pragma Preelaborate;
   procedure test;
   private
   ----------------------------
   -- Graphics Mode Register --
   ----------------------------
   type Graphics_Mode_Register_Write_Mode is (Mode_0, Mode_1, Mode_2, Mode_3);
   for Graphics_Mode_Register_Write_Mode use 
      (
         Mode_0 => 2#00#,
         Mode_1 => 2#01#,
         Mode_2 => 2#10#,
         Mode_3 => 2#11#
      );
   type Graphics_Mode_Register is
      record
         WM : Graphics_Mode_Register_Write_Mode;
         Read_Mode : Boolean;
         Odd_Even : Boolean;
         Shift_Register_Mode : Boolean;
         Color_Mode : Boolean;
      end record
         with Size => 8;
   for Graphics_Mode_Register use record
      WM at 0 range 0 .. 1;
      Read_Mode at 0 range 3 .. 3;
      Odd_Even at 0 range 4 .. 4;
      Shift_Register_Mode at 0 range 5 .. 5;
      Color_Mode at 0 range 6 .. 6;
      end record;

   -----------------------------------
   -- Miscellaneous Output Register --
   -----------------------------------
   type Clock_Select is (
      Clock_25M_640_320_PELs,
      Clock_28M_720_360_PELs,
      Clock_External
   );
   for Clock_Select use (
      Clock_25M_640_320_PELs => 2#00#,
      Clock_28M_720_360_PELs => 2#01#,
      Clock_External         => 2#10#
   );
   type Miscellaneous_Output_Register
 is
   record
      IOS : Boolean;
      ERAM : Boolean;
      CS : Clock_Select;
      HSP : Boolean;
      VSP : Boolean;
   end record
      with Size => 8;
   for Miscellaneous_Output_Register use
   record
      IOS at 0 range 0 .. 0;
      ERAM at 0 range 1 .. 1;
      CS at 0 range 2 .. 3;
      HSP at 0 range 6 .. 6;
      VSP at 0 range 7 .. 7;
      end record;


end VGA;