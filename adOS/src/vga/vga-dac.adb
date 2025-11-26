
package body VGA.DAC is
   
   procedure load_default_palette is
   begin
      Write_Address (0);

      for C of Default_Palette loop
         Write_Palette_Data_Register (C.Red);
         Write_Palette_Data_Register (C.Green);
         Write_Palette_Data_Register (C.Blue);
      end loop;
   end load_default_palette;

end VGA.DAC;