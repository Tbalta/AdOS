------------------------------------------------------------------------------
--                          VGA-GRAPHIC_CONTROLLER                          --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with VGA.Graphic_Controller;
with x86.Port_Io;
with SERIAL;
with Interfaces; use Interfaces;
with Ada.Unchecked_Conversion;

with VGA.Graphic_Controller.Registers; use VGA.Graphic_Controller.Registers;

package body VGA.Graphic_Controller is

   -------------------------------
   -- Compute_Needed_Memory_Map --
   -------------------------------
   function Compute_Needed_Memory_Map
     (Width, Height : Positive; Pixel_Size : Positive) return Memory_Map_Addressing
   is
      Storage_Needed : Positive := Width * Height * Pixel_Size / System.Storage_Unit;
   begin

      if Storage_Needed <= 32 * 1024 then
         return B0000_32KB;
      end if;

      if Storage_Needed <= 64 * 1024 then
         return A0000_64KB;
      end if;

      if Storage_Needed <= 128 * 1024 then
         return A0000_128KB;
      end if;
      raise Program_Error;
   end Compute_Needed_Memory_Map;


   procedure Set_Graphic_Controller_For_Mode (mode : VGA_mode)
   is
      Memory_Map : Memory_Map_Addressing;
   begin
      if mode.vga_type = alphanumeric then
        Memory_Map := B0000_32KB;
      else
        Memory_Map := Compute_Needed_Memory_Map (mode.Pixel_Width, mode.Pixel_Height, 8);
      end if;
      Write_Set_Reset_Register ((others => False));
      Write_Enable_Set_Reset_Register ((others => False));
      Write_Color_Compare_Register ((others => False));
      Write_Data_Rotate_Register ((Rotate_Count => 0, Function_Select => No_Function));
      Write_Read_Map_Select_Register (0);

      if mode.vga_type = alphanumeric then
         Write_Graphics_Mode_Register
         ((WM                   => Mode_0,
            Read_Mode           => False,
            Odd_Even            => True,
            Shift_Register_Mode => False,
            Color_Mode          => False));
      else
         Write_Graphics_Mode_Register
         ((WM                  => Mode_0,
            Read_Mode           => False,
            Odd_Even            => False,
            Shift_Register_Mode => False,
            Color_Mode          => mode.Colors = 256));
      end if;

      if mode.vga_type = alphanumeric then
         -- in this mode map1 and map3 need to be chained
         Write_Miscellaneous_Register
         ((Graphics_Mode => False, Odd_Even => True, Memory_Map => Memory_Map));
      else
         Write_Miscellaneous_Register
         ((Graphics_Mode => True, Odd_Even => False, Memory_Map => Memory_Map));
      end if;

      Write_Color_Dont_Care_Register ((others => False));
      Write_Bit_Mask_Register ((others => True));
   end Set_Graphic_Controller_For_Mode;
end VGA.Graphic_Controller;
