with VGA.Sequencer;
with x86.Port_Io;
package body VGA.Sequencer is

   procedure Write_Data (Value : Data_Type)
   is
      procedure Write is new x86.Port_IO.Write_Port_8 (Data_Register_Address, Data_Type);
   begin
      Write_Address (Index);
      Write (Value);
   end Write_Data;

   function Read_Data return Data_Type
   is
      function Read is new x86.Port_IO.Read_Port_8 (Data_Register_Address, Data_Type);
   begin
      Write_Address (Index);
      return Read;
   end Read_Data;

end VGA.Sequencer;