# mbp-ubuntu

[![Build Status](https://travis-ci.com/marcosfad/mbp-ubuntu.svg?branch=master)](https://travis-ci.com/marcosfad/mbp-ubuntu)

UBUNTU 20.04 ISO with Apple T2 patches built-in (Macbooks produced >= 2018).

All available Apple T2 drivers are integrated with this iso. Most things work, besides those mentioned in [not working section](#not-working).

Kernel - <https://github.com/marcosfad/mbp-ubuntu-kernel>

Drivers:

- Apple T2 (audio, keyboard, touchpad) - <https://github.com/MCMrARM/mbp2018-bridge-drv>
- Apple SMC - <https://github.com/MCMrARM/mbp2018-etc>
- Touchbar - <https://github.com/roadrunner2/macbook12-spi-driver/tree/mbp15>

> Tested on: Macbook Pro 16,1 16" 2019 i9 TouchBar

```
Boot ROM Version:	220.270.99.0.0 (iBridge: 16.16.6571.0.0,0)
macOS Mojave: 10.14.6 (18G103)
```

## How to install

- Turn off secure boot - <https://support.apple.com/en-us/HT208330>
- Download .iso from releases section - <https://github.com/marcosfad/mbp-ubuntu/releases/latest>
  - If it's splitted into multiple zip parts, you need to join splitted files into one and then extract it via `unzip` or extract them directly via `7z x` or `7za x`
    - <https://unix.stackexchange.com/questions/40480/how-to-unzip-a-multipart-spanned-zip-on-linux>
- Burn the image on USB stick >=8GB via:
  - dd - `dd bs=4M if=/home/user/Downloads/ubuntu-20.04-beta-minimal-mbp.iso of=/dev/sdc conv=fdatasync status=progress`
  - rufus (GPT)- <https://rufus.ie/>
  - balenaEtcher- <https://www.balena.io/etcher/>
  - don't use `livecd-iso-to-disk`, because it's overwriting grub settings
- Install Ubuntu
  - Boot directly from macOS boot manager. (You can boot into it by pressing and holding option key after clicking the power-on button).
    - There will be three boot options available, usually the third one works for me. (There are three of them, because there are three partitions in ISO: 1) ISO9660: with installer data, 2) fat32, 3) hfs+)
  - I recommend to shrink (resize) macOS APFS partition and not removing macOS installation entirely from your MacBook, because it's the only way to keep your device up-to-date. macOS OS updates also contains security patches to EFI/Apple T2
    - HowTo: <https://www.anyrecover.com/hard-drive-recovery-data/resize-partition-mac/> # Steps to Resize Mac Partition
  - You should use standard partition layout during partitioning your Disk in anaconda, because i haven't tested LVM scenario yet. <https://github.com/marcosfad/mbp-ubuntu/issues/2>
    - /boot/efi - 1024MB fat32
    - /boot - 1024MB EXT4
    - / - xxxGB EXT4

- Put wifi firmware files to `/lib/firmware/brcm/`
  - tutorial - <https://github.com/mikeeq/mbp-fedora-kernel/#working-with-mbp-fedora-kernel>
- You can change mappings of ctrl, fn, option keys (PC keyboard mappings) by creating `/etc/modprobe.d/hid_apple.conf` file and recreating grub config. All available modifications could be found here: <https://github.com/free5lot/hid-apple-patched>
```
# /etc/modprobe.d/hid_apple.conf
options hid_apple swap_fn_leftctrl=1
options hid_apple swap_opt_cmd=1

grub2-mkconfig -o /boot/efi/EFI/ubuntu/grub.cfg
```

## Not working

- Dynamic audio input/output change (on connecting/disconnecting headphones jack)
- TouchID - (@MCMrARM is working on it - https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-528545490)
- Thunderbolt (is disabled, because driver was causing kernel panics (not tested with 5.5 kernel))
- Microphone (it's recognised with new apple t2 sound driver, but there is a low mic volume amp)

## TODO


## Known issues

- Kernel/Mac related issues are mentioned in kernel repo

- Macbooks with Apple T2 can't boot EFI binaries from HFS+ formatted ESP - only FAT32 (FAT32 have to be labelled as msftdata).

- `ctrl+x` is not working in GRUB, so if you are trying to change kernel parameters - start your OS by clicking `ctrl+shift+f10` on external keyboard

## Docs

- Discord: <https://discord.gg/Uw56rqW>
- WiFi firmware: <https://packages.aunali1.com/apple/wifi-fw/18G2022>
- Linux on a MBP Late 2016: <https://gist.github.com/gbrow004/096f845c8fe8d03ef9009fbb87b781a4>

### Ubuntu

- <https://help.ubuntu.com/community/LiveCDCustomization>
- <https://itnext.io/how-to-create-a-custom-ubuntu-live-from-scratch-dd3b3f213f81>

### Github

- GitHub issue (RE history): <https://github.com/Dunedan/mbp-2016-linux/issues/71>
- VHCI+Sound driver (Apple T2): <https://github.com/MCMrARM/mbp2018-bridge-drv/>
- hid-apple keyboard backlight patch: <https://github.com/MCMrARM/mbp2018-etc>
- alsa/pulseaudio config files: <https://gist.github.com/MCMrARM/c357291e4e5c18894bea10665dcebffb>
- TouchBar driver: <https://github.com/roadrunner2/macbook12-spi-driver/tree/mbp15>
- Kernel patches (all are mentioned in github issue above): <https://github.com/aunali1/linux-mbp-arch>
- ArchLinux kernel patches: <https://github.com/ppaulweber/linux-mba>
- ArchLinux installation guide: <https://gist.github.com/TRPB/437f663b545d23cc8a2073253c774be3>
- hid-apple-patched module for changing mappings of ctrl, fn, option keys: <https://github.com/free5lot/hid-apple-patched>
- Audio configuration: <https://gist.github.com/kevineinarsson/8e5e92664f97508277fefef1b8015fba>

## Credits

- @mikeeq - thanks for the amazing work in mbp-fedora
- @MCMrARM - thanks for all RE work
- @ozbenh - thanks for submitting NVME patch
- @roadrunner2 - thanks for SPI (touchbar) driver
- @aunali1 - thanks for ArchLinux Kernel CI
- @ppaulweber - thanks for keyboard and Macbook Air patches
- @kevineinarsson - thanks for the audio settings
- @roadrunner2 - thanks for the overview
