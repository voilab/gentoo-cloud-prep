# Clean up portage
emerge --verbose=n --depclean
eix-update
emaint all -f
eselect news read all
eclean-dist --destructive
sed -i '/^USE=\"\${USE}\ \ build\"$/d' /etc/portage/make.conf

# clean up system
passwd -d root
passwd -l root
for i in $(find /var/log -type f); do echo > $i; done
for i in $(find /tmp -type f); do rm -f $i; done

find /usr/share/man/ -mindepth 1  -maxdepth 1 -path "/usr/share/man/man*" -prune -o -exec rm -rf {} \;
