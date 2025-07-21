with Interfaces;  use Interfaces;
with x86.Port_IO; use x86.Port_IO;
with SERIAL;      use SERIAL;
with Ada.Unchecked_Conversion;

package body Atapi is
   pragma Suppress (All_Checks);

   procedure busy_wait (Controller : ATA_CONTROLLER) is
      status : Unsigned_8;
      BSY    : constant Unsigned_8 := Shift_Left (1, 7);
   begin
      loop
         status := Inb (getReg (Controller, ATA_REG_STATUS));
         if ((status and BSY) = 0) then
            return;
         end if;
      end loop;
   end busy_wait;

   procedure wait_packet_request (Controller : ATA_CONTROLLER) is
      status : Unsigned_8;
      DRQ    : constant Unsigned_8 := Shift_Left (1, 3);
      ERR    : constant Unsigned_8 := Shift_Left (1, 0);
   begin
      loop
         status := Inb (getReg (Controller, ATA_REG_STATUS));
         if ((status and DRQ) /= 0) or ((status and ERR) = 0) then
            return;
         end if;
      end loop;
   end wait_packet_request;

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
      send_line ("Selecting device" & Unsigned_8 (ATA_DEVICE'Enum_Rep (Device))'Image);
      currentController := Controller;
      currentDevice := Device;

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

   function isAtapiDevice (Controller : ATA_CONTROLLER; Device : ATA_DEVICE) return Boolean is
      type Signature_Array is array (0 .. 3) of Unsigned_8;
      Signature        : Signature_Array := (0, 0, 0, 0);
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
        ("Signature: "
         & Signature (0)'Image
         & " "
         & To_Integer (getReg (Controller, ATA_REG_SECTOR_COUNT))'Image);
      return Signature = (ATAPI_SIG_SC, ATAPI_SIG_LBA_LO, ATAPI_SIG_LBA_MI, ATAPI_SIG_LBA_HI);
   end isAtapiDevice;

   procedure discoverAtapiDevices is
   begin
      for Controller in ATA_CONTROLLER'First .. ATA_CONTROLLER'Last loop
         for Device in ATA_MASTER .. ATA_SLAVE loop
            if isAtapiDevice (Controller, Device) then
               send_line ("Found ATAPI device on " & Controller'Image & " " & Device'Image);
               return;
            end if;
         end loop;
      end loop;
   end discoverAtapiDevices;

   procedure send_packet (packet : SCSI_PACKET) is
      type Packet_Array is array (0 .. (SCSI_PACKET'Size / Unsigned_16'Size) - 1) of Unsigned_16
      with Pack;
      function toArray is new
        Ada.Unchecked_Conversion (Source => SCSI_PACKET, Target => Packet_Array);
      to_send              : Packet_Array := toArray (packet);
      PACKET_DATA_TRANSMIT : constant Unsigned_8 := 2;
   begin
      Outb (getReg (currentController, ATA_REG_FEATURES), 0);
      Outb (getReg (currentController, ATA_REG_SECTOR_COUNT), 0);
      Outb (getReg (currentController, ATA_REG_LBA_MI), Unsigned_8 (CD_BLOCK_SIZE and 16#FF#));
      Outb
        (getReg (currentController, ATA_REG_LBA_HI), Unsigned_8 (Shift_Right (CD_BLOCK_SIZE, 8)));
      Outb (getReg (currentController, ATA_REG_COMMAND), Unsigned_8 (16#A0#));
      wait_packet_request (currentController);
      for i in to_send'Range loop
         Outw (getReg (currentController, ATA_REG_DATA), to_send (i));
         --  SERIAL.send_line ("Sent " & to_send (i)'Image);
      end loop;
      --  SERIAL.send_line ("Sent packet");
      --  SERIAL.send_line ("Controller " & currentController'Image);
      --  SERIAL.send_line
      --    ("port " &
      --     Unsigned_16 (ATA_CONTROLLER'Enum_Rep (currentController))'Image);
      while Inb (getReg (currentController, ATA_REG_SECTOR_COUNT)) /= PACKET_DATA_TRANSMIT loop
         null;
      end loop;
   end send_packet;

   function read_block (lba : Integer; buffer : out SECTOR_BUFFER) return Integer is
      packet    : SCSI_PACKET :=
        (opcode             => 16#a8#,
         lba_lo             => Unsigned_8 (Unsigned_32 (lba) and 16#FF#),
         lba_milo           => Unsigned_8 (Shift_Right (Unsigned_32 (lba), 8) and 16#FF#),
         lba_mihi           => Unsigned_8 (Shift_Right (Unsigned_32 (lba), 16) and 16#FF#),
         lba_hi             => Unsigned_8 (Shift_Right (Unsigned_32 (lba), 24) and 16#FF#),
         transfer_length_lo => 1,
         others             => 0);
      size_read : Integer := 0;
      data      : Unsigned_16;

   begin
      --  SERIAL.send_line ("Sending packet");
      send_packet (packet);
      --  SERIAL.send_line ("Reading block");
      declare
         size_hi : Unsigned_16 := Unsigned_16 (Inb (getReg (currentController, ATA_REG_LBA_HI)));
         size_lo : Unsigned_16 := Unsigned_16 (Inb (getReg (currentController, ATA_REG_LBA_MI)));
      begin
         size_read := Integer (Shift_Left (size_hi, 8) or size_lo);
      end;

      for i in 0 .. (Integer (buffer'Length / 2) - 1) loop
         data := Inw (getReg (currentController, ATA_REG_DATA));
         buffer (buffer'First + (i * 2)) := Unsigned_8 (data);
         buffer (buffer'First + (i * 2) + 1) := Unsigned_8 (Shift_Right (data, 8));
      end loop;
      --  buffer := fromWordPtr (buffer_word);
      SERIAL.send_line ("Read block: " & Unsigned_32 (size_read)'Image & " bytes");
      return size_read;
   end read_block;

end Atapi;
