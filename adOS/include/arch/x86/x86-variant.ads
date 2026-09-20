with Interfaces; use Interfaces;
package x86.Variant is
   pragma Pure;

      ------------------------------------
      -- Figure 3-8. Segment Descriptor --
      ------------------------------------

--    +-------------------+-----+------------+------------+---------------+
--    |31               24|23 20|19        16|15         8|7             0|  4
--    |     base[31:24]   |flags|limit[19:16]|    access  |  base[23:16]  |
--    +-------------------+-----+------------+------------+---------------+

--    +---------------------------------+---------------------------------+
--    |31                             16|15                              0|  0
--    |              base[15:00]        |     limit[15:0]                 |  
--    +-------------------------------------------------------------------+
   type Segment_Descriptor is record
      limit_low   : Unsigned_16;
      base_low    : Unsigned_16;
      base_mid    : Unsigned_8;
      access_byte : Unsigned_8;
      limit_high  : Unsigned_4;
      flags       : Unsigned_4;
      base_high   : Unsigned_8;
   end record
   with Size => 64;

   for Segment_Descriptor use
     record
       limit_low at 0 range 0 .. 15;
       base_low at 0 range 16 .. 31;
       base_mid at 0 range 32 .. 39;
       access_byte at 0 range 40 .. 47;
       limit_high at 0 range 48 .. 51;
       flags at 0 range 52 .. 55;
       base_high at 0 range 56 .. 63;
     end record;

   type Global_Descriptor_Pointer_T is record
      limit : Unsigned_16;
      base  : System.Address;
   end record;
   pragma Pack (Global_Descriptor_Pointer_T);
   
end x86.Variant;