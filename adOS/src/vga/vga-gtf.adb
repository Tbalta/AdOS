------------------------------------------------------------------------------
--                                 VGA-GTF                                  --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Util;
with Log;

package body VGA.GTF is
   package Logger renames Log.Serial_Logger;

   use all type Pixel_Count;

   function Round_Divide (a, b : Data_Type) return Data_Type is
   begin
      return (a + b - (b / b)) / b;
   end Round_Divide;

   function Get_Configuration
     (H_PIXELS : Pixel_Count; V_LINES : Scan_Line_Count) return VGA_Configuration
   is
      M             : constant Float := 600.0;
      C             : constant Float := 40.0;
      K             : constant Float := 128.0;
      J             : constant Float := 20.0;
      MIN_VSYNC_BP  : constant Float := 550.0;
      MIN_PORCH_RND : constant Scan_Line_Count := 1;
      V_SYNC_RND : constant := 3;
      H_SYNC_P : constant := 8.0;

      IDEAL_DUTY_CYCLE_SCALING : constant := 100;
      CELL_GRAN : constant Pixel_Count := 8;

      I_P_FREQ_RQD : constant := 25.0;

      function Pixel_Round_Divide is new Round_Divide (Pixel_Count);
      function Character_Round_Divide is new Round_Divide (Character_Count);

      function To_Character_Count (pixel : Pixel_Count) return Character_Count
      is ((Character_Count (Pixel_Round_Divide (pixel, CELL_GRAN))));

      H_PIXELS_RND : Pixel_Count := Pixel_Round_Divide (H_PIXELS, CELL_GRAN) * CELL_GRAN;
      V_LINES_RND  : Scan_Line_Count := V_LINES;

      -- 3. Find the pixel clock rate required:
      PIXEL_FREQ : constant Float := I_P_FREQ_RQD;

      -- 4. Find number of lines in left margin:
      LEFT_MARGIN : Pixel_Count := 0;

      -- 5. Find number of lines in rigth margin:
      RIGHT_MARGIN : Pixel_Count := 0;

      -- 6. Find total number of active pixels in image and left and right margins:
      TOTAL_ACTIVE_PIXELS : Pixel_Count := H_PIXELS_RND + RIGHT_MARGIN + LEFT_MARGIN;

      -- 7. Find the ideal horizontal period from the blanking duty cycle equation:
      test           : Float :=
        Util.sqrt
          (((100.0 - C) ** 2)
           + (4.0 * M * Float (TOTAL_ACTIVE_PIXELS + RIGHT_MARGIN + LEFT_MARGIN) / PIXEL_FREQ
              / 10.0));
      IDEAL_H_PERIOD : Float := ((C - 100.0) + (test)) * 1000.0 / 2.0 / M;

      -- 8. Find the ideal blanking duty cycle from the blanking duty cycle equation:
      IDEAL_DUTY_CYCLE : Float := C - (M * IDEAL_H_PERIOD / 1000.0);

      --    -- 9. Find the number of pixels in the blanking time to the nearest double character cell:
      H_BLANK : Pixel_Count :=
        Pixel_Count
          (Float'Rounding
             (Float (TOTAL_ACTIVE_PIXELS) * IDEAL_DUTY_CYCLE / (100.0 - IDEAL_DUTY_CYCLE)
              / (2.0 * Float (CELL_GRAN))))
        * Pixel_Count (2 * CELL_GRAN);

      --    -- 10. Find total number of pixels:
      TOTAL_PIXELS : Pixel_Count := TOTAL_ACTIVE_PIXELS + H_BLANK;

      --    -- 11. Find horizontal frequency:
      H_FREQ : Float := PIXEL_FREQ * 1000.0 / Float (TOTAL_PIXELS);

      --    -- 12. Find horizontal period:
      H_PERIOD : Float := 1000.0 / H_FREQ;

      --    -- 13. Find number of lines in Top margin:
      TOP_MARGIN : Scan_Line_Count := 0;

      --    -- 14. Find number of lines in Bottom margin:
      BOT_MARGIN : Scan_Line_Count := 0;

      --    -- 15. If interlace is required, then set variable INTERLACE = 0.5:
      INTERLACE : Float := 0.0; -- TODO: 0.5 if INTERLACE_REQUIRED else 0

      --    -- 16. Find the number of lines in V sync + back porch:
      V_SYNC_BP : Scan_Line_Count :=
        Scan_Line_Count (Float'Rounding (MIN_VSYNC_BP * H_FREQ / 1000.0));

      --    -- 17. Find the number of lines in V back porch alone:
      V_BACK_PORCH : Scan_Line_Count := V_SYNC_BP - V_SYNC_RND;

      --    -- 18. Find the total number of lines in Vertical field period
      TOTAL_V_LINES : Scan_Line_Count :=
        V_LINES_RND + TOP_MARGIN + BOT_MARGIN + Scan_Line_Count (INTERLACE) + V_SYNC_BP
        + MIN_PORCH_RND;


      --  7.6 Using Stage 1 Parameters to Derive Stage 2 Parameters
      --  1. Find the addressable lines per frame:
      ADDR_LINES_PER_FRAME : Scan_Line_Count := V_LINES_RND;

      --  3. Find the total number of lines in a frame:
      TOTAL_LINES_PER_FRAME : Scan_Line_Count := TOTAL_V_LINES;

      --  4. Find the total number of characters in a horizontal line:
      TOTAL_H_TIME : Character_Count := To_Character_Count (TOTAL_PIXELS);

      --  6. Find the horizontal addressable time (in chars):
      H_ADDR_TIME_CHARS : Character_Count :=
        Character_Count (Float'Rounding (Float (H_PIXELS_RND) / Float (CELL_GRAN)));

      --  8. Find the horizontal blanking time (in chars):
      H_BLANK_CHAR : Character_Count := To_Character_Count (H_BLANK);

      --  17. Find the number of pixels in the horizontal sync period:
      H_SYNC_PIXEL : Pixel_Count :=
        Pixel_Count
          (Float'Rounding (H_SYNC_P / 100.0 * Float (TOTAL_PIXELS) / Float (CELL_GRAN))
           * Float (CELL_GRAN));

      --  18. Find the number of pixels in the horizontal front porch period:
      H_FRONT_PORCH_PIXELS : Pixel_Count := (H_BLANK / 2) - H_SYNC_PIXEL;

      --  20. Find the number of characters in the horizontal sync period:
      H_SYNC_CHARS : Character_Count := Character_Count (H_SYNC_PIXEL / CELL_GRAN);

      --  22. Find the number of characters in the horizontal front porch period:
      H_FRONT_PORCH_CHARS : Character_Count := H_FRONT_PORCH_PIXELS / CELL_GRAN;

      --  32. Find the number of lines in the even blanking period:
      V_EVEN_BLANKING_LINES : Scan_Line_Count :=
        V_SYNC_BP + Scan_Line_Count (2.0 * INTERLACE) + MIN_PORCH_RND;

      --  36. Find the number of lines in the odd front porch period:
      V_ODD_FRONT_PORCH_LINES : Scan_Line_Count := MIN_PORCH_RND + Scan_Line_Count (INTERLACE);


      -- AdOS defined variable
      H_BLANK_START : Character_Count := H_ADDR_TIME_CHARS;
      V_BLANK_START : Scan_Line_Count := ADDR_LINES_PER_FRAME;

      H_SYNC_START : Character_Count := H_ADDR_TIME_CHARS + H_FRONT_PORCH_CHARS;
      V_SYNC_START : Scan_Line_Count := ADDR_LINES_PER_FRAME + V_ODD_FRONT_PORCH_LINES;
   begin
      Logger.Log_Info ("V_LINES_RND " & V_LINES_RND'Image);
      Logger.Log_Info ("test " & test'Image);
      Logger.Log_Info ("IDEAL_H_PERIOD" & IDEAL_H_PERIOD'Image);
      Logger.Log_Info ("IDEAL_DUTY_CYCLE" & IDEAL_DUTY_CYCLE'Image);
      Logger.Log_Info ("H_BLANK " & H_BLANK'Image);
      Logger.Log_Info ("H_FREQ " & H_FREQ'Image);
      Logger.Log_Info ("H_PERIOD " & H_PERIOD'Image);
      Logger.Log_Info ("V_SYNC_BP " & V_SYNC_BP'Image);
      Logger.Log_Info ("TOTAL_V_LINES " & TOTAL_V_LINES'Image);
      Logger.Log_Info ("H_ADDR_TIME_CHARS " & H_ADDR_TIME_CHARS'Image);
      return
        (Total_H             => TOTAL_H_TIME,
         Active_H_Chars      => H_ADDR_TIME_CHARS,

         Total_V             => TOTAL_V_LINES,
         Active_V_Chars      => ADDR_LINES_PER_FRAME,

         H_Blanking_Start    => H_BLANK_START,
         H_Blanking_Duration => H_BLANK_CHAR,

         V_Blanking_Start    => V_BLANK_START,
         V_Blanking_Duration => V_EVEN_BLANKING_LINES,

         H_Retrace_Start     => H_SYNC_START,
         H_Retrace_Duration  => H_SYNC_CHARS,

         V_Retrace_Start     => V_SYNC_START,
         V_Retrace_Duration  => V_SYNC_BP);
   end Get_Configuration;


end VGA.GTF;
