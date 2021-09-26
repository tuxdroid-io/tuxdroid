use box::ensure;
use box::mount;
use run_prog;
use stop;

function chroot::start() {
	
	echo "Starting the container ...";

	# Make sure the container is stopped
	chroot::stop;

	# Remount self with custom options
	mount --bind "$_distro_root" "$_distro_root";
	mount -o remount,dev,exec,suid "$_distro_root";

	# Linux mountpoints
	mount -t proc proc "$_distro_root/proc";
	mount -t sysfs sys "$_distro_root/sys";
	mount --rbind /dev "$_distro_root/dev" && \
		ensure::devNodes;
	if ! mountpoint -q "$_distro_root/dev/shm"; then {
		mkdir -p -m 1777 "$_distro_root/dev/shm" && \
			mount -o rw,nosuid,nodev,mode=1777 -t tmpfs tmpfs /dev/shm;
	} fi
	if ! mountpoint -q "$_distro_root/dev/pts"; then {
		mkdir -p "$_distro_root/dev/pts" && \
			mount -o rw,nosuid,noexec,gid=5,mode=620,ptmxmode=000 \
			-t devpts devpts /dev/pts;
	} fi

	# Setup /tmp
	rm -rf "$_distro_root/tmp" && \
		mkdir -m 0777 -p "$_distro_root/tmp" && \
		chmod +t "$_distro_root/tmp";

	# DNS
	_resolv_conf="$_distro_root/etc/resolv.conf"
	rm "$_resolv_conf" || true
	for _dns in "1.1.1.1" "1.0.0.1"; do
		echo "nameserver $_dns" >> "$_resolv_conf"
	done


	# Start chroot shell or components when specified
	if test -n "${COMPONENTS:-}"; then {
		true
	} else {
		chroot::run_prog /bin/bash -l || true;
	} fi
}

