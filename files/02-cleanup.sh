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
rm -f /usr/portage/distfiles/*
rm -f /etc/ssh/ssh_host_*
rm -f /root/.bash_history
rm -f /root/.nano_history
rm -f /root/.lesshst
rm -f /root/.ssh/known_hosts
rm -rf /usr/src/linux
rm -f /.touched
for i in $(find /var/log -type f); do echo > $i; done
for i in $(find /tmp -type f); do rm -f $i; done
