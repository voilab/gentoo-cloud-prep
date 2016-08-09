#!/usr/bin/env bash
#
# This will generate the spec, and run catalyst.
# I don't know if catalyst spec files can read vars, and didn't try it.
# Oh well, doesn't really matter, I suppose
#
# Also notice, you'll have to change the actual specfile generation for
# your own scenario.  I have a VM that poops out images for me, and these
# are the fields I use.

set -e -u -x -o pipefail

# Vars
. gentoo-cloud.config

if [[ "${PROFILE}" == "default/linux/amd64/13.0" ]]; then
  PROFILE_SHORTNAME="amd64-default"
  SOURCE_SUBPATH="stage3-amd64-current"
elif [[ "${PROFILE}" == "default/linux/amd64/13.0/no-multilib" ]]; then
  PROFILE_SHORTNAME="amd64-default-nomultilib"
  SOURCE_SUBPATH="stage3-amd64-nomultilib-current"
elif [[ "${PROFILE}" == "hardened/linux/amd64" ]]; then
  PROFILE_SHORTNAME="amd64-hardened"
  SOURCE_SUBPATH="stage3-amd64-hardened-current"
elif [[ "${PROFILE}" == "hardened/linux/amd64/no-multilib" ]]; then
  PROFILE_SHORTNAME="amd64-hardened-nomultilib"
  SOURCE_SUBPATH="stage3-amd64-hardened-nomultilib-current"
else
  echo 'invalid profile, exiting'
  exit 1
fi
export OUTFILE=${OUTFILE:-"${OUTDIR}/stage4-${PROFILE_SHORTNAME}-${DATE}.tar.bz2"}
export SPECFILE=${SPECFILE:-"${OUTDIR}/stage4-${PROFILE_SHORTNAME}.spec"}
mkdir -p "${OUTDIR}"

# Build the post catalyst script. Inject the user script if provided.
cat "${DIR}/files/01-prep.sh" > "${OUTDIR}/prep.sh"
echo >> "${OUTDIR}/prep.sh"
if [[ -f "${STAGE4_FSSCRIPT}" ]]; then
  echo "# --- ${STAGE4_FSSCRIPT} ---" >> "${OUTDIR}/prep.sh"
  cat "${STAGE4_FSSCRIPT}" >> "${OUTDIR}/prep.sh"
  echo >> "${OUTDIR}/prep.sh"
  echo "# --- ${STAGE4_FSSCRIPT} ---" >> "${OUTDIR}/prep.sh"
fi
cat "${DIR}/files/02-cleanup.sh" >> "${OUTDIR}/prep.sh"

# Build the spec file, first
cat > "${SPECFILE}" << EOF
subarch: amd64
target: stage4
rel_type: ${PROFILE_SHORTNAME}
profile: ${PROFILE}
source_subpath: ${SOURCE_SUBPATH}
cflags: -O2 -pipe -march=core2 -fomit-frame-pointer

pkgcache_path: /tmp/packages-${PROFILE_SHORTNAME}
kerncache_path: /tmp/kernel-${PROFILE_SHORTNAME}
portage_confdir: ${GIT_BASE_DIR}/portage_overlay

# Probably best made as parameters
snapshot: latest
version_stamp: ${DATE}

# Stage 4 stuff
stage4/use: ${STAGE4_USE}
stage4/packages: ${STAGE4_PACKAGES}
stage4/fsscript: ${OUTDIR}/prep.sh
stage4/root_overlay: root-overlay
stage4/rcadd: ${STAGE4_RCADD}

boot/kernel: gentoo
boot/kernel/gentoo/sources: ${KERNEL_SOURCES}
boot/kernel/gentoo/config: files/kernel-${PROFILE_SHORTNAME}.config
boot/kernel/gentoo/extraversion: openstack
boot/kernel/gentoo/gk_kernargs: --all-ramdisk-modules

# all of the cleanup...
stage4/unmerge:
  sys-kernel/genkernel
  sys-kernel/gentoo-sources

stage4/empty:
  /root/.ccache
  /tmp
  /usr/portage/distfiles
  /usr/src
  /var/cache/edb/dep
  /var/cache/genkernel
  /var/empty
  /var/run
  /var/state
  /var/tmp

stage4/rm:
  /etc/*-
  /etc/*.old
  /etc/ssh/ssh_host_*
  /root/.*history
  /root/.lesshst
  /root/.ssh/known_hosts
  /root/.viminfo
  # Remove any generated stuff by genkernel
  /usr/share/genkernel
  # This is 3MB of crap for each copy
  /usr/lib64/python*/site-packages/gentoolkit/test/eclean/testdistfiles.tar.gz
EOF

# Run catalyst
catalyst -f "${SPECFILE}"

# Clean up the spec file and post install script
rm "${SPECFILE}" "${OUTDIR}/prep.sh"

# Move the outputted image
mv "/var/tmp/catalyst/builds/${PROFILE_SHORTNAME}/stage4-amd64-${DATE}.tar.bz2" "${OUTFILE}"
