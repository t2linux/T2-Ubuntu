# mbp-ubuntu

UBUNTU 20.04 ISO with Apple T2 patches built-in. The ISO in from this repo should allow you to install ubuntu without using an external keyboard or mouse on a MacBook Pro. It work in my MacBook with T2.

[![CI](https://github.com/marcosfad/mbp-ubuntu/actions/workflows/CI.yml/badge.svg)](https://github.com/marcosfad/mbp-ubuntu/actions/workflows/CI.yml)

**If this repo helped you in any way, consider inviting a coffee to the people in the [credits](https://github.com/marcosfad/mbp-ubuntu#credits) or [me](https://paypal.me/marcosfad).**

This repo is a rework of the great work done by [@mikeeq](https://github.com/mikeeq/mbp-fedora)

I'm using the Kernel from - <https://github.com/t2linux/T2-Ubuntu-Kernel>

Using additional drivers:
- [Apple T2 (apple-bce) (audio, keyboard, touchpad)](https://github.com/t2linux/apple-bce-drv)
- [Touchbar (apple-ibridge, apple-ib-tb, apple-ib-als)](https://github.com/t2linux/apple-ib-drv)
- [mbpfan](https://github.com/networkException/mbpfan)

Bootloader is configure correctly out of the box. No workaround needed.

## How to install (Based on mikeeq/mbp-fedora)

1. Reduce the size of the mac partition in MacOS
   * HowTo: [Steps to Resize Mac Partition](https://www.anyrecover.com/hard-drive-recovery-data/resize-partition-mac/)
2. Turn off secure boot and allow booting from external media - <https://support.apple.com/en-us/HT208330>
3. Download .iso from releases section - <https://github.com/marcosfad/mbp-ubuntu/releases/latest>
   
   If it's split into multiple zip parts, i.e.: livecd.zip and livecd.z01 you need to download all zip parts and then
    * join split files into one and then extract it via unzip 
      * <https://unix.stackexchange.com/questions/40480/how-to-unzip-a-multipart-spanned-zip-on-linux>
    * or extract downloaded zip parts directly using:
      * on Windows winrar or other supported tool like 7zip
      * on Linux you can use p7zip, dnf install p7zip and then to extract 7za x livecd.zip
      * on MacOS you can use
        * the unarchiver from AppStore: <https://apps.apple.com/us/app/the-unarchiver/id425424353?mt=12>
        * or you can install p7zip via brew brew install p7zip and use 7za x livecd.zip command mentioned above
          * to install brew follow this tutorial: <https://brew.sh/>
4. Next you can check the SHA256 checksum of extracted .ISO to verify if your extraction process went well

   MacOS: `shasum -a 256 ubuntu-20.04.iso`
   Linux `sha256sum ubuntu-20.04.iso`
   please compare it with a value in sha256 file available in github releases

5. Burn the image on USB stick >=8GB via:
   * `dd`
     * Linux `sudo dd bs=4M if=/home/user/Downloads/ubuntu-20.04.iso of=/dev/sdc conv=fdatasync status=progress`
     * MacOS 
       ```bash
       diskutil list # found which number has the USB
       sudo diskutil umountDisk /dev/diskX
       sudo dd bs=4096 if=ubuntu-20.04-XXX.iso of=/dev/diskX
       ```
     * if `dd` is not working for you for some reason you can try to install `gdd` via `brew` and use GNU `dd` command instead `sudo gdd bs=4M if=ubuntu-20.04-XXX.iso of=/dev/diskX conv=fdatasync status=progress`
     
   * Rufus (GPT)- <https://rufus.ie/>, if prompted use DD mode
   * Please don't use livecd-iso-to-disk as it's overwriting ISO default grub settings and Ubuntu will not boot correctly!
    
6. Boot in Recovery mode and allow booting unknown OS
7. Restart and immediately press the option key until the Logo come up
8. Select "EFI Boot" (the third option was the one that worked for me)
9. Launch Ubuntu Live
10. Use Ubiquity to install (just click on it)
11. **[IMPORTANT]** Select the options that work for you and use for the partition the following setup:
     * Leave the efi boot as preselected by the installer. Your Mac will keep on working without problems.
     * Add a ext4 partition and mounted as `/boot` (1024MB).
     * Add a ext4 partition and monted as `/` (rest).
     * Select the `/boot` partition as a target for GRUB installation, otherwise the system won't boot.
12. Run the installer (In my case it had some problem removing some packages at the end, but this is no real problem)
13. Shutdown and remove the USB Drive
14. Start again using the option key. Select the new efi boot.
15. Enjoy.

See <https://wiki.t2linux.org/distributions/ubuntu/installation/> for more details.

## Configuration

- If wifi do not work out of the box, you can try to install the firmware using `sudo dpkg -i /usr/src/iso-firmware.deb`
  More details you can find on <https://wiki.t2linux.org/guides/wifi/>
- To install additional languages, install appropriate langpack via apt `sudo apt-get install language-pack-[cod] language-pack-gnome-[cod] language-pack-[cod]-base language-pack-gnome-[cod]-base `
    - see <https://askubuntu.com/questions/149876/how-can-i-install-one-language-by-command-line>
- You can change mappings of ctrl, fn, option keys (PC keyboard mappings) by creating `/etc/modprobe.d/hid_apple.conf` file and recreating grub config. All available modifications could be found here: <https://github.com/free5lot/hid-apple-patched>
```
# /etc/modprobe.d/hid_apple.conf
options hid_apple swap_fn_leftctrl=1
options hid_apple swap_opt_cmd=1
```
- I switch the touchbar to show f* by default. If you like another configuration, change /etc/modprobe.d/apple-tb.conf or remove it.
- To update grub, run: `grub-mkconfig -o /boot/grub/grub.cfg`
- If you have problems with shutdown and your mac has an AMD video Card, try deactivating the dpm on kernel (by adding `amdgpu.dpm=0` to the kernel options) or use copy the udev rule (`sudo cp /usr/src/udev_rules_d_30-amdgpu-pm.rules /etc/udev/rules.d/30-amdgpu-pm.rules`)

## MISC

### Activate Grub Menu

For the people who want to have a menu, they can modify `/etc/default/grub` with the following changes:
```
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=10
```
and then:
`sudo update-grub`

### Crashes with amdgpu or shutdown issues

Try to disable the power management by adding `amdgpu.dpm=0` to the kernel command line or disabling it temporarily using: 
```shell
echo high | sudo tee /sys/bus/pci/drivers/amdgpu/0000:??:??.?/power_dpm_force_performance_level
```

if that fix the issue for you, you can make this change permanent using:

```shell
sudo su
cat << EOF > /etc/udev/rules.d/30-amdgpu-pm.rules
KERNEL=="card0", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="high"
EOF
```

## Update to newer kernels

**IF YOU UPDATE THE KERNEL, REMEMBER TO ADD THE REQUIRED DRIVERS AGAIN.**

### The easy way:

The live cd includes a script to download the latest T2-Ubuntu-Kernel. Just run `update_kernel_mbp`.

### Another way:

Check <https://github.com/marcosfad/mbp-ubuntu/blob/master/files/chroot_build.sh> to see how it is done.

Or read <https://wiki.t2linux.org/guides/kernel/>

## Know issues

- Checksum is failing for 2 files: md5sum.txt and /boot/grub/bios.img

## Not working (Following the mikeeq/mbp-fedora)

- Dynamic audio input/output change (on connecting/disconnecting headphones jack)
- TouchID - (@MCMrARM is working on it - <https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-528545490>)
- Microphone (it's recognised with new apple t2 sound driver, but there is a low mic volume amp)

## TODO

- ISO is using gzip initramfs. It would be great to change it lz4
- Optimize the software installed.

## Known issues (Following the mikeeq/mbp-fedora)

- Kernel/Mac related issues are mentioned in kernel repo
- `ctrl+x` is not working in GRUB, so if you are trying to change kernel parameters - start your OS by clicking `ctrl+shift+f10` on external keyboard

## Docs

- Discord: <https://discord.gg/Uw56rqW> Shout out to the great community support. If you are not there yet, you must definitely join us.
- WiFi firmware: <https://packages.aunali1.com/apple/wifi-fw/18G2022>
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
- @MCMrARM - thanks for all RE work
- @ozbenh - thanks for submitting NVME patch
- @roadrunner2 - thanks for SPI (touchbar) driver
- @aunali1 - thanks for ArchLinux Kernel CI, the continuous support on discord and your continuous efforts.
- @ppaulweber - thanks for keyboard and Macbook Air patches
- @kevineinarsson - thanks for the audio settings

## (deprecated) Which kernel to choose

I've pre installed several different kernel, to allow better support to different hardware.

If your macbook came with Big Sur preinstalled, you should use a bigsur version of kernel.

If your macbook came with mojave, you should use a mojave version of the kernel.

This will allow you to activate wifi in your macbook. See [this page for more information about wifi drivers](https://wiki.t2linux.org/guides/wifi/)

I've recommend starting with the HWE Kernel. That one comes from Ubuntu own repository and I have had great performance with it.
