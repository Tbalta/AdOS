------------------------------------------------------------------------------
--                                 X86-UTIL                                 --
--                                                                          --
--                                 B o d y                                  --
-- (c) 2026 AdOS                                                            --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------

package body x86.util is
   procedure gnat_personality is
   begin
      while True loop
         null;
      end loop;
   end gnat_personality;

   procedure unwind_resume is
   begin
      while True loop
         null;
      end loop;
   end unwind_resume;
end x86.util;
