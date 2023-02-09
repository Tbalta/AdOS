with Interfaces;  use Interfaces;
with x86.Port_IO; use x86.Port_IO;
with SERIAL;      use SERIAL;
package body Atapi is
   pragma Suppress (All_Checks);

   procedure waitForDrive (Controller : ATA_CONTROLLER) is
      dummy : Unsigned_8;
   begin
      dummy := Inb (getReg (Controller, ATA_REG_STATUS));
      dummy := Inb (getReg (Controller, ATA_REG_STATUS));
      dummy := Inb (getReg (Controller, ATA_REG_STATUS));
      dummy := Inb (getReg (Controller, ATA_REG_STATUS));
   end waitForDrive;

   procedure selectDevice (Controller : ATA_CONTROLLER; Device : ATA_DEVICE) is
      DCR : constant System.Address := getDcr (Controller);

      SRST              : constant Unsigned_8 := Shift_Left (1, 2);
      INTERRUPT_DISABLE : constant Unsigned_8 := Shift_Left (1, 1);
   begin
      --  if currentController /= Controller then
      --     currentController := Controller;
      --     currentDevice     := Device;
      --  send_line ("dcR: " & DCR'Image);
      Outb (DCR, SRST);
      Outb (DCR, INTERRUPT_DISABLE);
      Outb (getReg (Controller, ATA_REG_DRIVE), ATA_DEVICE'Enum_Rep (Device));
      send_line
        ("Selecting device" & Unsigned_8 (ATA_DEVICE'Enum_Rep (Device))'Image);

      --     send_line ("Selecting ctrl");

      --  end if;
      --  if currentDevice /= Device then
      --     currentDevice := Device;
      --     Outb
      --   (getReg (Controller, ATA_REG_DRIVE), ATA_DEVICE'Enum_Rep (Device));
      --     send_line ("Selecting device" & ATA_DEVICE'Enum_Rep (Device));
      --  end if;
      waitForDrive (Controller);

   end selectDevice;

   function isAtapiDevice
     (Controller : ATA_CONTROLLER; Device : ATA_DEVICE) return Boolean
   is
      type Signature_Array is array (0 .. 3) of Unsigned_8;
      Signature        : Signature_Array     := (0, 0, 0, 0);
      ATAPI_SIG_SC     : constant Unsigned_8 := 16#01#;
      ATAPI_SIG_LBA_LO : constant Unsigned_8 := 16#01#;
      ATAPI_SIG_LBA_MI : constant Unsigned_8 := 16#14#;
      ATAPI_SIG_LBA_HI : constant Unsigned_8 := 16#EB#;
   begin
      selectDevice (Controller, Device);
      Signature (0) := Inb (getReg (Controller, ATA_REG_SECTOR_COUNT));
      Signature (1) := Inb (getReg (Controller, ATA_REG_LBA_LO));
      Signature (2) := Inb (getReg (Controller, ATA_REG_LBA_MI));
      Signature (3) := Inb (getReg (Controller, ATA_REG_LBA_HI));
      send_line
        ("Signature: " & Signature (0)'Image & " " &
         To_Integer (getReg (Controller, ATA_REG_SECTOR_COUNT))'Image);
      return
        Signature =
        (ATAPI_SIG_SC, ATAPI_SIG_LBA_LO, ATAPI_SIG_LBA_MI, ATAPI_SIG_LBA_HI);
   end isAtapiDevice;

   procedure discoverAtapiDevices is
   begin
      for Controller in ATA_CONTROLLER'First .. ATA_CONTROLLER'Last loop
         for Device in ATA_MASTER .. ATA_SLAVE loop
            if isAtapiDevice (Controller, Device) then
               send_line
                 ("Found ATAPI device on " & Controller'Image & " " &
                  Device'Image);
            end if;
         end loop;
      end loop;
   end discoverAtapiDevices;
end Atapi;
