# gentoo-cloud-prep

Some scripts to help with the following:

- Get the latest stage3 and portage snapshot from a mirror
- Catalyst that shit up into a stage4 for your own voodoo
- Prepare a physical disk based on that stage4, throw grub on it, generate a qcow2 image

### Prep and Usage: How do?

First we need some packages.

`# emerge catalyst qemu parted app-crypt/gkeys grub:2`

Now we can run `catalyst` and `qemu-img`.  If you only need the stage4, you can omit `qemu`.

Run the scripts in order, and you'll have a shiny new set of files, depending on what you wanted.

set the profile you want, valid ones are as follows

- default/linux/amd64/13.0
- default/linux/amd64/13.0/no-multilib
- hardened/linux/amd64
- hardened/linux/amd64/no-multilib

`export PROFILE="default/linux/amd64/13.0"`

Of note to hardened users is that this uses catalyst, which uses chroots, so you need to allow grsec things for chroots

### Environment variables

The following environment variables are used to customize the build process.

__MIRROR__: `http://gentoo.osuosl.org`
The Gentoo mirror used to download stage3 and portage archives. See https://www.gentoo.org/downloads/mirrors/

__BUILD_DIR__: `/var/tmp/catalyst/builds`
Catalyst build directory. Must match your settings in `/etc/catalyst/catalyst.conf`.

__PORTAGE_DIR__: `/var/tmp/catalyst/snapshots`
Directory in which the portage snapshots are stored. Must match your settings in `/etc/catalyst/catalyst.conf`.

__PROFILE__: `default/linux/amd64/13.0`
Profiles supported are as follows:
* default/linux/amd64/13.0
* default/linux/amd64/13.0/no-multilib
* hardened/linux/amd64
* hardened/linux/amd64/no-multilib

### Quick Overview: What do?

- `01-get-stage3.sh` will get the latest stage3 for you, from whatever mirror is supplied in the script.  You can use the default, but it's throttled for traffic outside my IP range.
- `02-catalyst-that-shit.sh` will take the stage3 generated a moment ago, and spit out a stage4 for you.  You will have to change variables here, I haven't included any overlays.  Stop here if you only want a stage4.
- `03-prep-that-image.sh` will take that stage4 that you just generated, and first wipe the target disk (entirely), make a partition table, `mkfs.ext4` it, splat the stage4 on it, and newest portage.  It will then unmount it, and throw grub on it.  After that, it will `dd` the disk into a raw image, and then `qemu-img convert` that raw image into a `qcow2` format, then remove the raw image.

### License: No don't!

Just kidding, do whatever you want.  Unless that involves blaming me.  Don't blame me.
