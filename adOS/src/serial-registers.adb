------------------------------------------------------------------------------
--                             SERIAL.REGISTERS                             --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2025 Tanguy Baltazart                                                --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
with x86.Port_IO;
with System.Storage_Elements; use System.Storage_Elements;
with System;
with System.Address_To_Access_Conversions;

package body SERIAL.Registers is

   -----------------------------
   -- Receive Buffer Register --
   -----------------------------
   function Read_Receive_Buffer (COM : x86.Port_IO.Port_Address) return Receive_Buffer_Register
   is
      function Read_RBR is new x86.Port_IO.Read_Port_8 (Get_Receive_Buffer_Port (COM), Receive_Buffer_Register);
   begin
      return Read_RBR;
   end Read_Receive_Buffer;

   ------------------------------
   -- Transmit Buffer Register --
   ------------------------------
   procedure Write_Transmit_Buffer (COM : x86.Port_IO.Port_Address; Value : Transmit_Buffer_Register)
   is
      procedure Write_TBR is new x86.Port_IO.Write_Port_8 (Get_Transmit_Buffer_Port (COM), Transmit_Buffer_Register);
   begin
      Write_TBR (Value);
   end Write_Transmit_Buffer;

   -------------------------------
   -- Divisor Low/High Register --
   -------------------------------
   procedure Write_Divisor_Low (COM : x86.Port_IO.Port_Address; Value : Unsigned_8)
   is
      procedure Write_DLR is new x86.Port_IO.Write_Port_8 (Get_Divisor_Low_Port (COM), Unsigned_8);
   begin
      Write_DLR (Value);
   end Write_Divisor_Low;

   procedure Write_Divisor_High (COM : x86.Port_IO.Port_Address; Value : Unsigned_8)
   is
      procedure Write_DHR is new x86.Port_IO.Write_Port_8 (Get_Divisor_High_Port (COM), Unsigned_8);
   begin
      Write_DHR (Value);
   end Write_Divisor_High;

   ---------------------------
   -- Line_Control_Register --
   ---------------------------
   procedure Write_Line_Control_Register (COM : x86.Port_IO.Port_Address; LCR : Line_Control_Register)
   is
      procedure Write_LCR is new x86.Port_IO.Write_Port_8 (Get_Line_Control_Register_Port (COM), Line_Control_Register);
   begin
      Write_LCR (LCR);
   end Write_Line_Control_Register;

   function Read_Line_Control_Register (COM : x86.Port_IO.Port_Address) return Line_Control_Register
   is
      function Read_LCR is new x86.Port_IO.Read_Port_8 (Get_Line_Control_Register_Port (COM), Line_Control_Register);
   begin
      return Read_LCR;
   end Read_Line_Control_Register;

   ---------------------------
   -- FIFO_Control_Register --
   ---------------------------
   procedure Write_FIFO_Control_Register (COM : x86.Port_IO.Port_Address; FCR : FIFO_Control_Register)
   is
      procedure Write_FCR is new x86.Port_IO.Write_Port_8 (Get_FIFO_Control_Register_Port (COM), FIFO_Control_Register);
   begin
      Write_FCR (FCR);
   end Write_FIFO_Control_Register;

   --------------------------
   -- Line_Status_Register --
   --------------------------
   function Read_Line_Status_Register (COM : x86.Port_IO.Port_Address) return Line_Status_Register
   is
      function Read_LSR is new x86.Port_IO.Read_Port_8 (Get_Line_Status_Register_Port (COM), Line_Status_Register);
   begin
      return Read_LSR;
   end Read_Line_Status_Register;

end SERIAL.Registers;
