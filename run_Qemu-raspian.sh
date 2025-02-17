#!/bin/bash
set -e

echo "Starting the preparation of partitions..."

## Prepare the partitions
# sudo rm -rf ./mnt/ || true
# mkdir -p ./mnt/{boot,rootfs}
# if [ -f rootfs.img ]; then
#     echo -e "\e[32mrootfs.img already exists\e[0m"
# else
#     echo "Creating rootfs.img..."
#     qemu-img create rootfs.img 4G
#     echo "Please use cfdisk to create the following partitions:"
#     echo "1. A primary partition of type FAT32 for boot."
#     echo "2. A primary partition of type Linux for rootfs."
#     echo "Press Enter to continue..."
#     read
#     sudo cfdisk ./rootfs.img
# fi

# echo -e "e[32Setting up loop device...\e[0m"
# loopdevice=$(sudo losetup --show --partscan -f ./rootfs.img)
# echo "Formatting partitions..."
# sudo mkfs.fat "${loopdevice}"p1
# sudo mkfs.ext4 "${loopdevice}"p2
# echo -e "\e[32mMounting partitions...\e[0m"
# sudo mount "${loopdevice}"p1 ./mnt/boot
# sudo mount "${loopdevice}"p2 ./mnt/rootfs

echo -e "\e[32mMounting sdimg partitions...\e[0m"
## mount wic partitions
# sudo rm -rf ./raspios/ || true
# mkdir -p ./raspios/{boot,rootfs}
# rm -rf ./*[0-9]*.img || true
# cp ../*[0-9]*.*zip .
# unzip ./*zip
image=$(ls ./2*[0-9]*.img)
qemu-img resize "$image" 4G
raspiosImage=$(sudo losetup --show --partscan -f "$image")
sudo mount "${raspiosImage}"p1 ./raspios/boot
# sudo mount "${raspiosImage}"p2 ./raspios/rootfs

echo "Copying files..."
## Copy the files
sudo cp -r ./raspios/boot/bcm2710-rpi-3-b.dtb .
sudo cp -r ./raspios/boot/kernel8.img .
sync
echo -e "\e[34mCleaning up...\e[0m"
echo -e "\e[34mUnmounting partitions...\e[34m"
## Unmount the partitions
sudo umount ./raspios/boot
sudo losetup -d "$raspiosImage"
echo -e "\e[32mRunning Qemu...\e[0m"
## Run Qemu
qemu-system-arm64 \
    -M raspi3b \
    -cpu cortex-a53 \
    -m 1G \
    -smp 4 \
    -dtb bcm2710-rpi-3-b.dtb \
    -kernel kernel8.img \
    -drive file="$image",format=raw,if=sd \
    -append "console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootwait rw earlyprintk loglevel=7" \
    -usbdevice keyboard -usbdevice mouse \
    -netdev user,id=net0 -device usb-net,netdev=net0 \
    -display gtk

echo "Done."
