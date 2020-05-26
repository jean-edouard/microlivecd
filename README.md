# microlivecd
A gutted Debian installation CD that autoboots and logs to serial

This project was originally created to facilitate automated tests related to UEFI Secure Boot.  
The Debian netinstall CD is great, as it can boot on both BIOS and UEFI systems, and is even properly signed for Secure Boot.  
It can't however be used for automated tests as-is (nor was it ever supposed to be), since:
- Grub waits forever for user selection
- The kernel is booted with `quiet`
- The kernel is not booted with serial console options

This script intends to fix all of the above, while also:
- Reducing the size of the iso
- Booting to a shell instead of the installer
