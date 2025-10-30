package x86.util is
   pragma Preelaborate;
private
   procedure gnat_personality
   with Export => True, Convention => C, External_Name => "__gnat_personality_v0";

   procedure unwind_resume
   with Export => True, Convention => C, External_Name => "_Unwind_Resume";

end x86.util;
