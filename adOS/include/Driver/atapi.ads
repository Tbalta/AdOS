with Interfaces;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;

package Atapi is
   pragma Preelaborate;

   type Atapi_Device_id is new Integer range 0 .. 3;
   subtype SECTOR_BUFFER_INDEX is Integer range 1 .. 2_048;
   type SECTOR_BUFFER is array (SECTOR_BUFFER_INDEX) of Interfaces.Unsigned_8
   with Convention => C, Size => 2_048 * 8;
   type SECTOR_BUFFER_PTR is access all SECTOR_BUFFER;
   function read_block
     (Device_id : Atapi_Device_id; lba : Natural; buffer : out SECTOR_BUFFER) return Integer;
   procedure discoverAtapiDevices;

   function Is_Present (Device_id : Atapi_Device_id) return Boolean;

private
   type ATA_CONTROLLER is (ATA_SECONDARY, ATA_PRIMARY);
   for ATA_CONTROLLER use (ATA_SECONDARY => 16#170#, ATA_PRIMARY => 16#1F0#);
   type ATA_DEVICE is (ATA_MASTER, ATA_SLAVE);
   for ATA_DEVICE use (ATA_MASTER => 0, ATA_SLAVE => 16#10#);
   PRIMARY_DCR   : constant System.Address := To_Address (16#3F6#);
   SECONDARY_DCR : constant System.Address := To_Address (16#376#);
   CD_BLOCK_SIZE : constant Interfaces.Unsigned_16 := 2_048;

   sector_data : aliased SECTOR_BUFFER := (others => 0);

   type ATA_REG is new Storage_Offset;
   ATA_REG_DATA          : ATA_REG := ATA_REG (0);
   ATA_REG_FEATURES      : ATA_REG := ATA_REG (1);
   ATA_REG_ERROR_INFO    : ATA_REG := ATA_REG (1);
   ATA_REG_SECTOR_COUNT  : ATA_REG := ATA_REG (2);
   ATA_REG_SECTOR_NB     : ATA_REG := ATA_REG (3);
   ATA_REG_LBA_LO        : ATA_REG := ATA_REG (3);
   ATA_REG_CYLINDER_LOW  : ATA_REG := ATA_REG (4);
   ATA_REG_LBA_MI        : ATA_REG := ATA_REG (4);
   ATA_REG_CYLINDER_HIGH : ATA_REG := ATA_REG (5);
   ATA_REG_LBA_HI        : ATA_REG := ATA_REG (5);
   ATA_REG_DRIVE         : ATA_REG := ATA_REG (6);
   ATA_REG_HEAD          : ATA_REG := ATA_REG (6);
   ATA_REG_COMMAND       : ATA_REG := ATA_REG (7);
   ATA_REG_STATUS        : ATA_REG := ATA_REG (7);

   ATA_CMD_IDENTIFY_PACKET : constant Interfaces.Unsigned_8 := 16#A1#;

   procedure waitForDrive (Controller : ATA_CONTROLLER);
   procedure selectDevice (Controller : ATA_CONTROLLER; Device : ATA_DEVICE);
   function getDcr (controller : ATA_CONTROLLER) return System.Address
   is (if controller = ATA_PRIMARY then PRIMARY_DCR else SECONDARY_DCR);
   function getReg (controller : ATA_CONTROLLER; reg : ATA_REG) return System.Address
   is (To_Address (ATA_CONTROLLER'Enum_Rep (controller)) + Storage_Offset (reg));
   function isAtapiDevice (Controller : ATA_CONTROLLER; Device : ATA_DEVICE) return Boolean;

   type SCSI_PACKET is record
      opcode               : Interfaces.Unsigned_8;
      flag_lo              : Interfaces.Unsigned_8;
      lba_hi               : Interfaces.Unsigned_8;
      lba_mihi             : Interfaces.Unsigned_8;
      lba_milo             : Interfaces.Unsigned_8;
      lba_lo               : Interfaces.Unsigned_8;
      transfer_length_hi   : Interfaces.Unsigned_8;
      transfer_length_mihi : Interfaces.Unsigned_8;
      transfer_length_milo : Interfaces.Unsigned_8;
      transfer_length_lo   : Interfaces.Unsigned_8;
      flag_hi              : Interfaces.Unsigned_8;
      control              : Interfaces.Unsigned_8;
   end record
   with Convention => C, Size => 12 * 8, Pack => True;

   type ATAPI_DEVICE_INFO is record
      Present    : Boolean := False;
      Controller : ATA_CONTROLLER;
      Device     : ATA_DEVICE;
   end record;

   type ATAPI_DEVICE_ARRAY is array (ATAPI_Device_ID) of ATAPI_DEVICE_INFO;
   Devices : ATAPI_DEVICE_ARRAY :=
     (others => (Present => False, Controller => ATA_PRIMARY, Device => ATA_MASTER));
end Atapi;
