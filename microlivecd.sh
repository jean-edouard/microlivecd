#!/bin/bash -e

# Requires xorriso:
# $ sudo apt-get install xorriso [On Debian/Ubuntu systems]
# $ sudo yum install xorriso     [On CentOS/RHEL systems]

# Config:
ARCH="amd64 ppc64el"
DEB_VERSION="10.4.0"

for arch in $ARCH; do
    TMP=`mktemp -d`
    ISO=`mktemp --suffix=iso`
    DEST="`pwd`/microlivecd_${arch}.iso"

    # Remove any existing MicroLiveCD iso
    rm -f $DEST

    # Download the Debian netinst iso
    wget -O $ISO https://cdimage.debian.org/debian-cd/current/${arch}/iso-cd/debian-${DEB_VERSION}-${arch}-netinst.iso

    # Extract and remove the Debian iso
    xorriso -osirrox on -indev $ISO -extract / $TMP
    rm $ISO

    # Modify the iso contents
    cd $TMP
    # xorriso extracts everything as readonly, add write permission for the current user
    chmod -R u+w * .disk
    chmod +x .disk/mkisofs
    # Remove big directories
    rm -rf pool
    # Only keep the first Grub menuentry
    sed -i '/}/q' boot/grub/grub.cfg
    # Rename it to just "Go"
    sed -i "s|\(menuentry .* '\).*\('.*\)|\1Go\2|" boot/grub/grub.cfg
    # Add (as first line) a timeout of 1 second
    sed -i '1 i\set timeout=1' boot/grub/grub.cfg
    # Fix the linux cmdline to:
    # - boot in text mode
    # - start a shell instead of the Debian installer
    # - *not* be quiet
    # - log to ttyS0
    sed -i 's|linux\s\+\([^ ]\+\).*|linux \1 init=/bin/ash console=tty1 console=ttyS0|' boot/grub/grub.cfg

    # Build microlivecd.iso
    # .disk/mkisofs contains the xorriso command used to build the Debian iso
    # Some changes are required:
    # - Set the iso name and location
    sed -i "s|-V '[^']\+'|-V 'MicroLiveCD'|" .disk/mkisofs
    sed -i "s|-o [^ ]\+|-o ${DEST}|" .disk/mkisofs
    # - Remove all jigdo-related settings
    sed -i 's|-jigdo-[^ ]\+ [^ ]\+||g' .disk/mkisofs
    sed -i 's|-md5-list [^ ]\+||' .disk/mkisofs
    sed -i 's|-checksum_algorithm_iso [^ ]\+||' .disk/mkisofs
    # - Fix the location of isohdpfx.bin
    sed -i 's|[^ ]*isohdpfx.bin|/usr/share/syslinux/isohdpfx.bin|' .disk/mkisofs
    # - Fix the source directory
    sed -i "s|boot1 CD1|CD1|" .disk/mkisofs
    sed -i "s|CD1|${TMP}|" .disk/mkisofs
    # Run the script
    ./.disk/mkisofs

    # Leave the tmp directory and remove it
    cd - > /dev/null
    rm -rf $TMP
done
