# About
Firmware image extracted from SPI ROM of WiiMu A31 module of iRiver LS-150 WiFi speaker, 
as well as some tools to allow custom code execution

# Installation
## Prerequisites
You need to install telnet, expect and curl for the script to work. Binwalk is recommended for digging in SPI ROM contents
## Automatic install
There's an automatic installation script that should enable telnet on boot and disable idle timeout called install_telnet.sh.
Usage: `install_telnet.sh <IP address>`
## Manual install

# Background
## Hardware
The speaker uses WiiMu A31 WiFi audio module by LinkPlay: https://linkplay.com/solutions/wifi-module/.  
Module specs: MIPS Mediatek MT7688 SoC, 64 MB RAM, 16 MB SPI flash  
Some docs and pinout: https://fccid.io/2AAPP-A31  
Manual: https://fccid.io/2AAPP-A31/Users-Manual/15-A31-UserMan-3034717

Audio module is connected to the microcontroller (MCU) board with UART at 57600 8n1

MCU board microcontroller: JL AC1619D99111-00  
Manufacturer site: http://www.zh-jieli.com/  
No documentation found; some documentation for a different model by the same manufacturer here: https://fccid.io/ANATEL/01407-16-04646/Manual_AC4601/66273B12-041E-4A03-9215-527C6B181524

Volume control, display, capacitive buttons are all connected to the MCU (not the WiFi board).

### Screws

Security Torx T10 AND T15, sunk in 70mm deep holes. Yes, there's ONE SECURITY TORX T15 SCREW in addition to other 7 security T10 - because screw you! 

eBay links: [T10](https://www.ebay.com/itm/T8-T9-T10-Torx-Security-Tamperproof-Screwdriver-Tool-Disassembly-for-Xbox-360/382584483353), [T15](https://www.ebay.com/itm/Red-Clear-Plastic-Handle-T15-Security-Torx-Screwdriver-Tool-WS-A1H2/282693846521)

### Ethernet
Ethernet is available on the WiFi module but not connected to anything,
soldering an RJ45 connector with transformer and a few passives should enable Ethernet (NOT TESTED YET).

Ethernet connection schematics available in the module manual, section 2.5.1

### USB Host
USB is available on the WiFi module but not connected to anything.
Connecting USB data lines to the rear panel USB should be possible (NOT TESTED).

## Software
### Dumping ROM
I used a SOIC8 clip to connect to the SPI ROM IC and dump the ROM. ROM dump is `spi.bin`.

### Extracting ROM
Using dd and mkimage is possible, but I never managed to extract anything useful due to mkimage format mismatch and other issues with uImage. 

What worked brilliantly was binwalk. Just run `binwalk -e spi.rom` and voila.

### Mounts
```
rootfs on / type rootfs (rw)
/dev/root on / type squashfs (ro,relatime)
proc on /proc type proc (rw,relatime)
none on /var type ramfs (rw,relatime)
none on /etc type ramfs (rw,relatime)
none on /tmp type ramfs (rw,relatime)
none on /media type ramfs (rw,relatime)
none on /sys type sysfs (rw,relatime)
none on /dev/pts type devpts (rw,relatime,mode=600)
mdev on /dev type ramfs (rw,relatime)
devpts on /dev/pts type devpts (rw,relatime,mode=600)
/dev/mtdblock8 on /mnt type jffs2 (rw,relatime)
/dev/mtdblock9 on /vendor type jffs2 (rw,relatime)
```

#### jffs2 volumes
/mnt and /vendor are writable and persistent - a good place to keep files/scripts without having to rebuild initrd.

### Binaries
#### goahead
HTTP server, based on GoAhead 2.1.8. Vulnerable to `LD_PRELOAD` CGI attacks and god knows what else..
See e.g. https://www.rapid7.com/db/modules/exploit/linux/http/goahead_ldpreload
Not vulnerable to ShellShock because all scripts are using /bin/sh.

#### mv_ioguard
UART server, communicates with MCU  
Commands sent from WiFI module to MCU start with `AXX+`  
Commands sent from MCU to WiFI module start with `MCU+`

Examples:   
`AXX+MCU+VER` - get software? revision of the MCU  
`MCU+MUT+GET` - request current MUTE status

`strings mv_ioguard | grep AXX/MCU` for the full? list

####  rootApp
rootApp is the 'main app', processes commands `goahead` receives on the `httpapi.asp` endpoint and UART commands from `mv_ioguard`
Enable Telnet: there's a command for that! `507269765368656C6C:5f7769696d75645f` - translates to `PrivShell:_wiimud_`

Calling system() on unsanitized input happens when processing AIRPLAY_PASSWORD nvram variable, we'll use that to achieve persistence without having to patch initrd/go in with the SOIC8 clip.
Pseudo-code:
```C
sprintf(buf, "echo \"%s\" > %s", airplay_password, "/tmp/airplay_password");
system(buf);
```

Start your Airplay password with `";` and you can make it run whatever you put after that..

#### airplayd
AirPlay receiver, has some strings pointing to the capability of communicating with an i2c MFI authentication chip.

#### /system/workdir
Vendor-supplied extras, most need `LD_LIBRARY_PATH=/system/workdir/lib` to work.
Curl is available there, wget is available in busybox - to make copying files easier.
