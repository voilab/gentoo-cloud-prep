#!/usr/bin/env bash
#
# Okay, so here's some real meat.  We take a drive (as 02 said, I use a VM),
# and we spray that stage4 all over it.  Then we rub some grub (0.97) all over
# it to make it feel better, and then we box it up and ship it out.

set -e -u -o pipefail

# Vars
. gentoo-cloud.config

if [[ "${PROFILE}" == "default/linux/amd64/13.0" ]]; then
  PROFILE_SHORTNAME="amd64-default"
elif [[ "${PROFILE}" == "default/linux/amd64/13.0/no-multilib" ]]; then
  PROFILE_SHORTNAME="amd64-default-nomultilib"
elif [[ "${PROFILE}" == "hardened/linux/amd64" ]]; then
  PROFILE_SHORTNAME="amd64-hardened"
elif [[ "${PROFILE}" == "hardened/linux/amd64/no-multilib" ]]; then
  PROFILE_SHORTNAME="amd64-hardened-nomultilib"
else
  echo 'invalid profile, exiting'
  exit 1
fi

TARBALL=${TARBALL:-"${OUTDIR}/stage4-${PROFILE_SHORTNAME}-${DATE}.tar.bz2"}
TEMP_IMAGE=${TEMP_IMAGE:-"gentoo-${PROFILE_SHORTNAME}.img"}
TARGET_IMAGE=${TARGET_IMAGE:-"openstack-${PROFILE_SHORTNAME}-${DATE}.qcow2"}

# create a raw partition and do stuff with it
truncate -s 4G "${OUTDIR}/${TEMP_IMAGE}"
BLOCK_DEV=$(losetup -f --show "${OUTDIR}/${TEMP_IMAGE}")

# Okay, we have the disk, let's prep it
echo 'Building disk'
parted -s "${BLOCK_DEV}" mklabel gpt
parted -s --align=none "${BLOCK_DEV}" mkpart bios_boot 0 2M
parted -s --align=none "${BLOCK_DEV}" mkpart primary 2M 100%
parted -s "${BLOCK_DEV}" set 1 boot on
parted -s "${BLOCK_DEV}" set 1 bios_grub on
mkfs.ext4 -i 4096 -F "${BLOCK_DEV}p2"
e2label "${BLOCK_DEV}p2" cloudimg-rootfs

# Mount it
echo 'Mounting disk'
mkdir -p "${MOUNT_DIR}/${PROFILE_SHORTNAME}"
mount "${BLOCK_DEV}p2" "${MOUNT_DIR}/${PROFILE_SHORTNAME}"

# Expand the stage
echo 'Expanding tarball'
tar --xattrs -xjpf "${TARBALL}" -C "${MOUNT_DIR}/${PROFILE_SHORTNAME}"

if [[ ${ADD_PORTAGE} != 0 ]]; then
echo 'Adding in /usr/portage'
tar --xattrs -xjpf "${PORTAGE_DIR}/portage-latest.tar.bz2" -C "${MOUNT_DIR}/${PROFILE_SHORTNAME}/usr"
fi

# Install grub
echo 'Installing grub'
grub-install "${BLOCK_DEV}" --root-directory "${MOUNT_DIR}/${PROFILE_SHORTNAME}/"

# Clean up
echo 'Syncing; unmounting'
sync
umount "${MOUNT_DIR}/${PROFILE_SHORTNAME}"

# get rid of block mapping
losetup -d "${BLOCK_DEV}"

echo 'Converting raw image to qcow2'
qemu-img convert -c -f raw -O qcow2 "${OUTDIR}/${TEMP_IMAGE}" "${OUTDIR}/${TARGET_IMAGE}"

echo 'Cleaning up'
rm "${OUTDIR}/${TEMP_IMAGE}"
