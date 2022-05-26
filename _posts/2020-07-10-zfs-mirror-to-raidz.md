---
categories: homepage
title: Convert a ZFS mirror to raidz1 using a virtual device
---
It is not possible to convert a zfs vdev's type (e.g. raidz1 to raidz2). However, with a bit of trickery, we can convert a pool with one mirrored vdev into a pool with one raidz1 vdev, without having an extra hard drive on hand.

## Summary

We're going to create a zfs raidz1 vdev with a virtual device. This will allow us to create the raidz1 vdev with 1 fewer physical hard drive than we really have.

In a concrete example, let's say I have a current pool with one mirrored vdev:

```
zpool old-pool
    vdev mirror-1
        /dev/old_hdd_a
        /dev/old_hdd_b
```

We'll remove a device from that mirror:

```
zpool old-pool
    vdev device-1
        /dev/old_hdd_a
```

We'll use the removed `old_hdd_b`, along with my newly purchased `new_hdd_a` and a virtual device `/dev/loop1` to create a new pool:

```
zpool old-pool
    vdev device-1
        /dev/old_hdd_a
zpool new-pool
    vdev raidz-1
        /dev/old_hdd_b
        /dev/new_hdd_a
        /dev/loop1
```

We can then copy all our data over to the `new-pool`, destroy the `old-pool`, and use the `old_hdd_a` to replace the virtual device `/dev/loop1`.

## How-to

**WARNING: During this process, you will have no redundancy. ANY DISK FAILURE WILL RESULT IN LOSING _ALL_ OF YOUR DATA FROM YOUR _ENTIRE ZFS POOL_. Additionally, messing up a command might result in losing ALL YOUR DATA.** You should always have backups. Do not use this process for a business-critical pool. I'm just a home user with a bunch of linux isos and home backups, so I can afford to risk data loss in exchange for buying one less hard drive.

Ok, with that out of the way, let's get on to it. This info is cobbled together from a few forum posts around the web, and [this blog post on oracle.com](https://web.archive.org/web/20150915000000*/https://blogs.oracle.com/zhangfan/entry/how_to_turn_a_mirror) (no longer available, except on the Wayback Machine).

#### Baseline zfs setup

This guide will use device names assuming your initial pool looks like this in `zpool status -v`:

```
    NAME                                       STATE     READ WRITE CKSUM
    tank                                       ONLINE       0     0     0
      mirror-1                                 ONLINE       0     0     0
        old_hdd_a                              ONLINE       0     0     0
        old_hdd_b                              ONLINE       0     0     0
```

#### Detach one of your mirrored devices

```
> sudo zpool offline tank old_hdd_b
> sudo zpool detach tank old_hdd_b
```

Now, `zpool status -v` shows:

```
    NAME                                       STATE     READ WRITE CKSUM
    tank                                       ONLINE       0     0     0
        old_hdd_a                              ONLINE       0     0     0
```

#### Create a sparse file and mount it

Create the sparse file. This file will _look_ like it is the size you specify, but will take up 0 space on your disk:

```
> dd if=/dev/zero of=disk1.img bs=1 count=0 seek=10T  # Use the size of your largest disk for the `seek=` argument
```

Mount it as a loopback device:

```
> sudo losetup -f ./disk1.img
```

Check the device was mounted, and get its path:

```
> losetup -a  # Check in the output of this command to verify the disk was mounted
/dev/loop6: []: (/home/marckhouri/disk1.img)
```

#### Create the new pool and offline the virtual device

Use the loopback device path from the last step to create a new pool.

```
> sudo zpool create tankier raidz /dev/loop6 /dev/disk/by-id/old_hdd_b /dev/disk/by-id/new_hdd_a
```

Immediately take the virtual device offline so we don't write to it

```
> sudo zpool offline tankier /dev/loop6
```

Now, `zpool status -v` shows:

```
    NAME                                    STATE     READ WRITE CKSUM
    tank                                    ONLINE       0     0     0
        old_hdd_a                           ONLINE       0     0     0

    NAME                                    STATE     READ WRITE CKSUM
    tankier                                 DEGRADED     0     0     0
      raidz1-0                              DEGRADED     0     0     0
        loop6                               OFFLINE      0     0     0
        old_hdd_b                           ONLINE       0     0     0
        new_hdd_a                           ONLINE       0     0     0
```

#### Transfer your data

```
> sudo zfs snapshot tank@20200710
> sudo zfs send -Rv tank@20200710 | sudo zfs recv -vsF tankier
```

I saw ~350MBPS transfer speeds for this process. Use `-s` on the `recv` command to allow for session resumption in case the transfer is interrupted

#### Destroy the old pool and replace the virtual device with the old device

TODO

## Conclusion

That's it! Using a sparse file as a loopback device in your zfs pool is definitely a _bad idea_ if you care about your data, but it can be helpful if you're a home user who cares enough about saving $150 (or physically can't fit another drive in your chassis 😬).

---------------

## Addendum: full output of all commands as I went through this process

My setup wasn't exactly as described above, these are my details:

- I had 3x8TB in raidz1 and 2x10TB in mirror (~26TB usable).
- I bought 2 more 10TB drives.
- I setup a second pool with a 4x10TB raidz1 vdev made up of one of the 10TB drives from my mirror, the 2 new 10TB drives, and a virtual drive (~30TB usable).
    - My original pool new had 3x8TB in raidz1 and 1x10TB with no redundancy (still ~26TB usable).
- I transferred all my data from the old pool to the new pool
- I moved all the devices from my old pool to the new pool, so I ended with 3x8TB in raidz1 and 4x10TB in raidz1 (~46TB usable)

Here's a step by step log showing lots of output:

```sh
marckhouri@mars:~$ zfs list
NAME            USED  AVAIL  REFER  MOUNTPOINT
tank           19.5T  3.32T  19.3T  /tank
tank@20200426   141G      -  15.6T  -
tank@20200609  26.5G      -  18.0T  -
marckhouri@mars:~$ zpool status -v
  pool: tank
 state: ONLINE
  scan: resilvered 80K in 0h0m with 0 errors on Fri Jul 10 03:28:20 2020
config:

    NAME                                       STATE     READ WRITE CKSUM
    tank                                       ONLINE       0     0     0
      raidz1-0                                 ONLINE       0     0     0
        ata-WDC_WD80EMAZ-00WJTA0_7HK2UN3N      ONLINE       0     0     0
        ata-WDC_WD80EMAZ-00WJTA0_7HJX81NF      ONLINE       0     0     0
        ata-WDC_WD80EZAZ-11TDBA0_2YJMUYUD      ONLINE       0     0     0
      mirror-1                                 ONLINE       0     0     0
        ata-WDC_WD100EMAZ-00WJTA0_2YJGKGGD     ONLINE       0     0     0
        ata-WDC_WD100EMAZ-00WJTA0_JEGVWWZN     ONLINE       0     0     0
    cache
      nvme-HP_SSD_EX900_120GB_HBSE18433200255  ONLINE       0     0     0

marckhouri@mars:~$ sudo zpool offline tank ata-WDC_WD100EMAZ-00WJTA0_JEGVWWZN

marckhouri@mars:~$ zpool status
  pool: tank
 state: DEGRADED
status: One or more devices has been taken offline by the administrator.
    Sufficient replicas exist for the pool to continue functioning in a
    degraded state.
action: Online the device using 'zpool online' or replace the device with
    'zpool replace'.
  scan: resilvered 80K in 0h0m with 0 errors on Fri Jul 10 03:28:20 2020
config:

    NAME                                       STATE     READ WRITE CKSUM
    tank                                       DEGRADED     0     0     0
      raidz1-0                                 ONLINE       0     0     0
        ata-WDC_WD80EMAZ-00WJTA0_7HK2UN3N      ONLINE       0     0     0
        ata-WDC_WD80EMAZ-00WJTA0_7HJX81NF      ONLINE       0     0     0
        ata-WDC_WD80EZAZ-11TDBA0_2YJMUYUD      ONLINE       0     0     0
      mirror-1                                 DEGRADED     0     0     0
        ata-WDC_WD100EMAZ-00WJTA0_2YJGKGGD     ONLINE       0     0     0
        ata-WDC_WD100EMAZ-00WJTA0_JEGVWWZN     OFFLINE      0     0     0
    cache
      nvme-HP_SSD_EX900_120GB_HBSE18433200255  ONLINE       0     0     0

errors: No known data errors

marckhouri@mars:~$ sudo zpool detach tank ata-WDC_WD100EMAZ-00WJTA0_JEGVWWZN

marckhouri@mars:~$ zpool status
  pool: tank
 state: ONLINE
  scan: resilvered 80K in 0h0m with 0 errors on Fri Jul 10 03:28:20 2020
config:

    NAME                                       STATE     READ WRITE CKSUM
    tank                                       ONLINE       0     0     0
      raidz1-0                                 ONLINE       0     0     0
        ata-WDC_WD80EMAZ-00WJTA0_7HK2UN3N      ONLINE       0     0     0
        ata-WDC_WD80EMAZ-00WJTA0_7HJX81NF      ONLINE       0     0     0
        ata-WDC_WD80EZAZ-11TDBA0_2YJMUYUD      ONLINE       0     0     0
      ata-WDC_WD100EMAZ-00WJTA0_2YJGKGGD       ONLINE       0     0     0
    cache
      nvme-HP_SSD_EX900_120GB_HBSE18433200255  ONLINE       0     0     0

errors: No known data errors

marckhouri@mars:~$ dd if=/dev/zero of=disk1.img bs=1 count=0 seek=10T
0+0 records in
0+0 records out
0 bytes copied, 0.000302862 s, 0.0 kB/s

marckhouri@mars:~$ losetup -a
/dev/loop1: []: (/var/lib/snapd/snaps/core18_1754.snap)
/dev/loop4: []: (/var/lib/snapd/snaps/core_9289.snap)
/dev/loop2: []: (/var/lib/snapd/snaps/core18_1705.snap)
/dev/loop0: []: (/var/lib/snapd/snaps/canonical-livepatch_94.snap)
/dev/loop5: []: (/var/lib/snapd/snaps/canonical-livepatch_95.snap)
/dev/loop3: []: (/var/lib/snapd/snaps/core_9436.snap)

marckhouri@mars:~$ sudo losetup -f ./disk1.img

marckhouri@mars:~$ losetup -a
/dev/loop1: []: (/var/lib/snapd/snaps/core18_1754.snap)
/dev/loop6: []: (/home/marckhouri/disk1.img)
/dev/loop4: []: (/var/lib/snapd/snaps/core_9289.snap)
/dev/loop2: []: (/var/lib/snapd/snaps/core18_1705.snap)
/dev/loop0: []: (/var/lib/snapd/snaps/canonical-livepatch_94.snap)
/dev/loop5: []: (/var/lib/snapd/snaps/canonical-livepatch_95.snap)
/dev/loop3: []: (/var/lib/snapd/snaps/core_9436.snap)

marckhouri@mars:~$ sudo zpool create tankier raidz /dev/loop6 /dev/disk/by-id/ata-WDC_WD100EMAZ-00WJTA0_JEGVWWZN /dev/disk/by-id/ata-WDC_WD100EMAZ-00WJTA0_JEK4EW0N /dev/disk/by-id/ata-WDC_WD100EMAZ-00WJTA0_JEK5W8XN

marckhouri@mars:~$ zpool status -v
  pool: tank
 state: ONLINE
  scan: resilvered 80K in 0h0m with 0 errors on Fri Jul 10 03:28:20 2020
config:

    NAME                                       STATE     READ WRITE CKSUM
    tank                                       ONLINE       0     0     0
      raidz1-0                                 ONLINE       0     0     0
        ata-WDC_WD80EMAZ-00WJTA0_7HK2UN3N      ONLINE       0     0     0
        ata-WDC_WD80EMAZ-00WJTA0_7HJX81NF      ONLINE       0     0     0
        ata-WDC_WD80EZAZ-11TDBA0_2YJMUYUD      ONLINE       0     0     0
      ata-WDC_WD100EMAZ-00WJTA0_2YJGKGGD       ONLINE       0     0     0
    cache
      nvme-HP_SSD_EX900_120GB_HBSE18433200255  ONLINE       0     0     0

errors: No known data errors

  pool: tankier
 state: ONLINE
  scan: none requested
config:

    NAME                                    STATE     READ WRITE CKSUM
    tankier                                 ONLINE       0     0     0
      raidz1-0                              ONLINE       0     0     0
        loop6                               ONLINE       0     0     0
        ata-WDC_WD100EMAZ-00WJTA0_JEGVWWZN  ONLINE       0     0     0
        ata-WDC_WD100EMAZ-00WJTA0_JEK4EW0N  ONLINE       0     0     0
        ata-WDC_WD100EMAZ-00WJTA0_JEK5W8XN  ONLINE       0     0     0

errors: No known data errors

marckhouri@mars:~$ sudo zpool offline tankier /dev/loop6

marckhouri@mars:~$ zpool status -v
  pool: tank
 state: ONLINE
  scan: resilvered 80K in 0h0m with 0 errors on Fri Jul 10 03:28:20 2020
config:

    NAME                                       STATE     READ WRITE CKSUM
    tank                                       ONLINE       0     0     0
      raidz1-0                                 ONLINE       0     0     0
        ata-WDC_WD80EMAZ-00WJTA0_7HK2UN3N      ONLINE       0     0     0
        ata-WDC_WD80EMAZ-00WJTA0_7HJX81NF      ONLINE       0     0     0
        ata-WDC_WD80EZAZ-11TDBA0_2YJMUYUD      ONLINE       0     0     0
      ata-WDC_WD100EMAZ-00WJTA0_2YJGKGGD       ONLINE       0     0     0
    cache
      nvme-HP_SSD_EX900_120GB_HBSE18433200255  ONLINE       0     0     0

errors: No known data errors

  pool: tankier
 state: DEGRADED
status: One or more devices has been taken offline by the administrator.
    Sufficient replicas exist for the pool to continue functioning in a
    degraded state.
action: Online the device using 'zpool online' or replace the device with
    'zpool replace'.
  scan: none requested
config:

    NAME                                    STATE     READ WRITE CKSUM
    tankier                                 DEGRADED     0     0     0
      raidz1-0                              DEGRADED     0     0     0
        loop6                               OFFLINE      0     0     0
        ata-WDC_WD100EMAZ-00WJTA0_JEGVWWZN  ONLINE       0     0     0
        ata-WDC_WD100EMAZ-00WJTA0_JEK4EW0N  ONLINE       0     0     0
        ata-WDC_WD100EMAZ-00WJTA0_JEK5W8XN  ONLINE       0     0     0

marckhouri@mars:~$ zfs list
NAME            USED  AVAIL  REFER  MOUNTPOINT
tank           19.5T  3.32T  19.3T  /tank
tank@20200426   141G      -  15.6T  -
tank@20200609  26.5G      -  18.0T  -
tankier         453K  25.5T   140K  /tankier

marckhouri@mars:~$ sudo zfs send -Rv tank@20200710 | sudo zfs recv -vsF tankier
full send of tank@20200426 estimated size is 15.6T
send from @20200426 to tank@20200609 estimated size is 2.52T
send from @20200609 to tank@20200710 estimated size is 1.38T
total estimated size is 19.5T
TIME        SENT   SNAPSHOT
receiving full stream of tank@20200426 into tankier@20200426
06:35:04    205M   tank@20200426
06:35:05    544M   tank@20200426
06:35:06    881M   tank@20200426
06:35:07   1.19G   tank@20200426
06:35:08   1.50G   tank@20200426
06:35:09   1.77G   tank@20200426
[...] trimmed

# TODO: add the destroy and migration
```
