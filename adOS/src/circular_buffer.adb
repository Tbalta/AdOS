package body Circular_Buffer is
   

   function Pop (Buffer : access Buffer_Type) return Dequeue_Result is
   begin
      if Buffer.Head = Buffer.Tail then
         return (valid => False);
      end if;

      return Result : Dequeue_Result (True) do 
         Result.Value := Buffer.Buffer (Buffer.Tail);
         Buffer.Tail := Integer (Buffer.Tail + 1) mod Max_Size;
      end return;
   end Pop;


   procedure Push (Buffer : access Buffer_Type; item : in Element_Type)
   is
   begin
      if (Buffer.Head + 1 mod Max_Size) = Buffer.Tail then
         Buffer.Tail := Buffer.Tail + 1 mod Max_Size;
      end if;

      Buffer.Buffer (Buffer.Head) := item;
      Buffer.Head := Integer (Buffer.Head + 1) mod Max_Size;
   end Push;

   function Count (Buffer : Buffer_Type) return Integer
   is
   begin
      return Integer ((Max_Size + Buffer.Head - Buffer.Tail) mod Max_Size);
   end Count;



end Circular_Buffer;
