with Interfaces;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;

package Atapi is
   --  pragma Preelaborate;
   type ATA_CONTROLLER is (ATA_SECONDARY, ATA_PRIMARY);
   for ATA_CONTROLLER use
     (ATA_SECONDARY => 16#170#, ATA_PRIMARY => 16#1F0#);
   type ATA_DEVICE is (ATA_MASTER, ATA_SLAVE);
   for ATA_DEVICE use
     (ATA_MASTER => 0, ATA_SLAVE => 16#10#);

   PRIMARY_DCR   : constant System.Address := To_Address (16#3F6#);
   SECONDARY_DCR : constant System.Address := To_Address (16#376#);

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

   procedure discoverAtapiDevices;
   procedure waitForDrive (Controller : ATA_CONTROLLER);
   procedure selectDevice (Controller : ATA_CONTROLLER; Device : ATA_DEVICE);
   function getDcr (controller : ATA_CONTROLLER) return System.Address is
     (if controller = ATA_PRIMARY then PRIMARY_DCR else SECONDARY_DCR);
   function getReg
     (controller : ATA_CONTROLLER; reg : ATA_REG) return System.Address is
     (To_Address (ATA_CONTROLLER'Enum_Rep (controller)) +
      Storage_Offset (reg));
   function isAtapiDevice
     (Controller : ATA_CONTROLLER; Device : ATA_DEVICE) return Boolean;

   currentController : ATA_CONTROLLER;
   currentDevice     : ATA_DEVICE;

private
end Atapi;
