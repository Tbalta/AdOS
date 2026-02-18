with System.Storage_Elements; use System.Storage_Elements;
package SSE is
   pragma Preelaborate;

   procedure Enable_SSE;

private
   type SSE_Save_Area is new Storage_Array (1 .. 512)
      with Pack => True,
           Component_Size => 8,
           Convention => C;

   fxsave_region : SSE_Save_Area;
end SSE;