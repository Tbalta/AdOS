------------------------------------------------------------------------------
--                             VGA-SEQUENCER                                --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See LICENCE.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

with Interfaces; use Interfaces;
with VGA.Sequencer.Registers; use VGA.Sequencer.Registers;
package body VGA.Sequencer is

   ----------------------------
   -- Set_Sequencer_For_Mode --
   ----------------------------
   procedure Set_Sequencer_For_Mode (mode : VGA_mode)
   is
   begin
      Write_Reset_Register ((ASR => True, SR => True));
      Write_Clocking_Mode_Register ((D89 => mode.Box.Width = 8, SL => False, DC => False, SH4 => False, SO => False));

      --  In alphanumeric modes, the system writes the ASCII character
      --  code and attribute data to video memory maps 0 and 1,
      --  respectively. Memory map 2 contains the character font loaded by
      --  BIOS during an alphanumeric mode set. The font is used by the
      --  character generator to create the character image on the display.
      if mode.vga_type = alphanumeric then
         Write_Map_Mask_Register ((Map_0_Enable => True, Map_1_Enable => True, others => False));
      else
         Write_Map_Mask_Register ((others => True));
      end if;

      Write_Character_Map_Select_Register
        (To_Character_Map_Select_Register (Map_2_1st_8KB, Map_2_1st_8KB));

      -- In the alphanumeric modes, the programmer views maps 0 and 1 as
      --  a single buffer. 
      if mode.vga_type = alphanumeric then
         Write_Memory_Mode_Register ((Extended_Memory => True, Odd_Even => False, Chain_4 => False));
      else
         Write_Memory_Mode_Register ((Extended_Memory => True, Odd_Even => True, Chain_4 => True));
      end if;
   end Set_Sequencer_For_Mode;
end VGA.Sequencer;
