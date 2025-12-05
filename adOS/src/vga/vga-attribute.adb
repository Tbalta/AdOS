------------------------------------------------------------------------------
--                             VGA-ATTRIBUTE                                --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with VGA.Attribute;
with x86.Port_Io;
with Ada.Unchecked_Conversion;
with SERIAL;
with Interfaces; use Interfaces;

with VGA.Attribute.Registers; use VGA.Attribute.Registers;
package body VGA.Attribute is

   ------------------------------
   -- Reset_Attribute_Register --
   ------------------------------
   procedure Reset_Attribute_Register is
      function Read_ISR1 is new x86.Port_IO.Inb (Unsigned_8);
      Register : Unsigned_8;
      pragma Unreferenced (Register);
   begin
      Register := Read_ISR1 (x86.Port_IO.Port_Address (16#03DA#));
   end Reset_Attribute_Register;

   procedure Set_Attribute_For_Mode (mode : VGA_Mode) is
   begin
      Reset_Attribute_Register;
      for i in Internal_Palette_Register_Index range 0 .. 15 loop
         Write_Internal_Palette_Register (i, Internal_Palette_Register (i));
      end loop;

      if mode.vga_type = alphanumeric then
         Write_Attribute_Mode_Control_Register
         ((Graphic_Mode              => False,
            Mono_Emulation            => False,
            Enable_Line_Graphics      => mode.Box.Width = 9,
            Enable_Blink              => True,
            PEL_Panning_Compatibility => False,
            PEL_Width                 => False,
            P5_P4_Select              => False));
      else
         Write_Attribute_Mode_Control_Register
               ((Graphic_Mode              => True,
                  Mono_Emulation            => False,
                  Enable_Line_Graphics      => False,
                  Enable_Blink              => False,
                  PEL_Panning_Compatibility => False,
                  PEL_Width                 => mode.Colors = 256,
                  P5_P4_Select              => False));
      end if;
      Write_Overscan_Color_Register (0);
      Write_Color_Plane_Enable_Register (16#0F#);
      Write_Horizontal_PEL_Panning_Register (16#08#);
      Write_Color_Select_Register
        ((Select_Color_4 => False,
          Select_Color_5 => False,
          Select_Color_6 => False,
          Select_Color_7 => False));
   end Set_Attribute_For_Mode;

end VGA.Attribute;
