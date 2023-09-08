# T2-Ubuntu

The ISOs from this repo should allow you to install Ubuntu without using an external keyboard or mouse on a T2 Mac.

![CI](https://github.com/t2linux/T2-Ubuntu/actions/workflows/CI.yml/badge.svg?branch=jammy)

**If this repo helped you in any way, consider inviting a coffee to the people in the [credits](https://github.com/AdityaGarg8/T2-Ubuntu#credits), [link](https://wiki.t2linux.org/contribute/).**

Ubuntu ISO with Apple T2 patches built-in. Now we also support kubuntu thanks to [@lemmyg](https://github.com/lemmyg)!

Apple T2 drivers are integrated with this iso. 

This repo is a rework of the great work done by [@mikeeq](https://github.com/mikeeq/mbp-fedora). It originally was [@marcosfad's mbp-ubuntu repo](https://github.com/marcosfad/mbp-ubuntu) and has been transferred to [t2linux](https://github.com/t2linux).

Kernel is being used from - <https://github.com/t2linux/T2-Ubuntu-Kernel>

Using additional patches to support T2 Macs - <https://github.com/t2linux/linux-t2-patches>

Bootloader is configure correctly out of the box. No workaround needed.

## Installation

1. Reduce the size of the mac partition in MacOS.
2. Download ISO file from releases.
3. Copy it to a USB using dd (or gdd if installed over brew): 
```bash
diskutil list # found which number has the USB
diskutil umountDisk /dev/diskX
sudo gdd bs=4M if=ubuntu-20.04-5.6.10-mbp.iso of=/dev/diskX conv=fdatasync status=progress
```
#### Note
Other imaging tools such as Etcher or Rufus may not work as intended, if you are having trouble, use dd (or gdd if installed over brew)
4. Boot in Recovery mode and allow booting unknown OS.
5. Restart and immediately press and hold the option key until the Logo comes up.
6. Select "EFI Boot" (the third option was the one that worked for me)
7. Launch Ubuntu Live
8. Use Ubiquity to install (just click on it)
9. Select the options that work for you and use for the partition the following setup:
    * Leave the efi boot as preselected by the installer, unless you require a [separate efi partition](https://wiki.t2linux.org/guides/windows/#using-seperate-efi-partitions).
    * Add a ext4 partition and monted as `/`.
    * Swap and other partitions are optional.
10. Run the installer.
11. Shutdown and remove the USB Drive.
12. Start again using the option key. Select the new efi boot.
13. Enjoy.

## Configuration

- See <https://wiki.t2linux.org/guides/wifi/>
- To install additional languages, install appropriate langpack via apt `sudo apt-get install language-pack-[cod] language-pack-gnome-[cod] language-pack-[cod]-base language-pack-gnome-[cod]-base `
    - see https://askubuntu.com/questions/149876/how-can-i-install-one-language-by-command-line
- You can change mappings of ctrl, fn, option keys (PC keyboard mappings) by creating `/etc/modprobe.d/hid_apple.conf` file and recreating grub config. All available modifications could be found here: <https://github.com/free5lot/hid-apple-patched>
```
# /etc/modprobe.d/hid_apple.conf
options hid_apple swap_fn_leftctrl=1
options hid_apple swap_opt_cmd=1
```

## MISC

### Activate Grub Menu

For the people who want to have a menu, they can modify `/etc/default/grub` with the following changes:
```
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=10
```
and then:
`sudo update-grub`

## Update to newer kernels

Follow [this guide](https://github.com/t2linux/T2-Ubuntu-Kernel#pre-installation-steps).

## Know issues

- Checksum is failing for 2 files: md5sum.txt and /boot/grub/bios.img 

## Not working (Following the mikeeq/mbp-fedora)

- Dynamic audio input/output change (on connecting/disconnecting headphones jack)
- TouchID
- Thunderbolt (is disabled, because driver was causing kernel panics (not tested with 5.5 kernel))
- Microphone (it's recognised with new apple t2 sound driver, but there is a low mic volume amp)

## Known issues

- `ctrl+x` is not working in GRUB, so if you are trying to change kernel parameters - start your OS by pressing `F10` on external keyboard

## Docs

- Discord: <https://discord.gg/Uw56rqW> Shout out to the great community support. If you are not there yet, you must definitely join us.
- Linux on a MBP Late 2016: <https://gist.github.com/gbrow004/096f845c8fe8d03ef9009fbb87b781a4>
- Repack Bootable ISO: <https://wiki.debian.org/RepackBootableISO>
- <https://github.com/syzdek/efibootiso>

### Ubuntu

- <https://help.ubuntu.com/community/LiveCDCustomization>
- <https://itnext.io/how-to-create-a-custom-ubuntu-live-from-scratch-dd3b3f213f81>
- <https://help.ubuntu.com/community/LiveCDCustomizationFromScratch>
- <https://help.ubuntu.com/community/InstallCDCustomization>
- <https://linuxconfig.org/legacy-bios-uefi-and-secureboot-ready-ubuntu-live-image-customization>

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
- Ubuntu in MBP16: <https://gist.github.com/gbrow004/096f845c8fe8d03ef9009fbb87b781a4>

## Credits

- @mikeeq - thanks for the amazing work in mbp-fedora
- @marcosfad - thanks for the original work in mbp-ubuntu
- @MCMrARM - thanks for all RE work
- @ozbenh - thanks for submitting NVME patch
- @roadrunner2 - thanks for SPI (touchbar) driver
- @aunali1 - thanks for ArchLinux Kernel CI, the continuous support on discord and your continuous efforts.
- @ppaulweber - thanks for keyboard and Macbook Air patches
- @kevineinarsson - thanks for the audio settings
