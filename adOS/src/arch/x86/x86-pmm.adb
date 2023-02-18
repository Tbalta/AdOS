with SERIAL;
with Interfaces;              use Interfaces;
with Interfaces.C;            use Interfaces.C;
with System.Storage_Elements; use System.Storage_Elements;
package body x86.pmm is
    pragma Suppress (Index_Check);
    pragma Suppress (Overflow_Check);
    --  pragma Suppress (All_Checks);
    procedure Init (MB : multiboot_mmap) is
        pmmEntryCount     : Positive    := 1;
        pmmHeaderCount    : Integer     := 0;
        firstValidAddress : Unsigned_32 := 0;
        kernel_end        : Unsigned_32;
        pragma Import (C, kernel_end, "kernel_end");
        kernel_end_address : pmmMapAddress := To_Integer (kernel_end'Address);

        pmm_mmap_location : System.Address := kernel_end'Address;
    begin
        --  Computing pmm map entry count.
        for Index in MB'Range loop
            if MB (Index).entry_type = MULTIBOOT_MEMORY_AVAILABLE then
                SERIAL.send_line
                   ("Found available memory at " &
                    Unsigned_64 (MB (Index).base_addr)'Image & " of size " &
                    Unsigned_64 (MB (Index).length)'Image);
                pmmEntryCount  :=
                   pmmEntryCount +
                   Positive (MB (Index).length) / PMM_PAGE_SIZE;
                pmmHeaderCount := pmmHeaderCount + 1;
            end if;
        end loop;

        SERIAL.send_line ("Found " & pmmHeaderCount'Image & " Headers.");
        --  Setting pmm header.
        SERIAL.send_line ("Setting pmm header.");
        SERIAL.send_line ("kernel_end: " & kernel_end'Image);
        declare
            --  type pmm_header is new pmm_map_header (1 .. pmmHeaderCount);
            type pmm_header is
               new pmm_map_header (1 .. Positive (pmmHeaderCount));
            pmm_header_address : pmmMapAddress :=
               pmmMapAddress
                  ((Positive (kernel_end_address) + PMM_PAGE_SIZE) /
                   PMM_PAGE_SIZE * PMM_PAGE_SIZE);
            package pmm_header_conversion is new System
               .Address_To_Access_Conversions
               (pmm_header);
            pmm_header_ptr : access pmm_header :=
               pmm_header_conversion.To_Pointer
                  (To_Address (pmm_header_address));
            pmmHeaderIndex : Positive          := 1;
        begin
            for Index in MB'Range loop
                if MB (Index).entry_type = MULTIBOOT_MEMORY_AVAILABLE then
                    pmm_header_ptr (pmmHeaderIndex).base_addr :=
                       To_Address (Integer_Address (MB (Index).base_addr));
                    pmm_header_ptr (pmmHeaderIndex).length    :=
                       Unsigned_64 (MB (Index).length);
                    null;
                end if;
            end loop;
        end;

        -- Setting pmm map.
        SERIAL.send_line ("Setting pmm map.");
        declare
            subtype pmm_bitmap_effective is pmm_bitmap (1 .. pmmEntryCount);
            pmm_bitmap_effective_address : pmmMapAddress :=
               (pmmMapAddress
                   ((Positive (kernel_end_address) + PMM_PAGE_SIZE) / PMM_PAGE_SIZE *
                    PMM_PAGE_SIZE));
            package pmmBitmapConversion is new System
               .Address_To_Access_Conversions
               (pmm_map);
            pmm_map_ptr : access pmm_map :=
               pmmBitmapConversion.To_Pointer (pmm_mmap_location);
            pmmMapIndex : Positive       := 1;
        begin
            null;
        end;

    end Init;
end x86.pmm;
