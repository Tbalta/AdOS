with SERIAL;
with Interfaces;   use Interfaces;
with Interfaces.C; use Interfaces.C;
package body x86.pmm is
    pragma Suppress (Index_Check);
    pragma Suppress (Overflow_Check);
    pragma Suppress (All_Checks);
    procedure Init (MB : multiboot_mmap) is
        FreePageCount     : Unsigned_32 := 0;
        FirstValidAddress : Unsigned_32 := 0;
        kernel_end        : Unsigned_32;
        pragma Import (C, kernel_end, "kernel_end");

        pmm_mmap_location : System.Address := kernel_end'Address;
        pmm_mmap_ptr : access pmm_map;
    begin
        --  Computing pmm map entry count.
        for Index in MB'Range loop
            if MB (Index).entry_type = MULTIBOOT_MEMORY_AVAILABLE then
                SERIAL.send_line
                   ("Found available memory at " &
                    Unsigned_64 (MB (Index).base_addr)'Image & " of size " &
                    Unsigned_64 (MB (Index).length)'Image);
                --  FreePageCount := FreePageCount + MB (Index).length / PMM_PAGE_SIZE;
            end if;
        end loop;

    end Init;
end x86.pmm;
