use box::ensure;
use box::mount;
use run_prog;
use stop;

function chroot::start() {
	
	echo "Starting the container ...";

	# Make sure the container is stopped
	chroot::stop;

	# Remount self with custom options
	if test ! -v SUDID; then {
		mount --bind "$_distro_root" "$_distro_root";
		mount -o remount,dev,exec,suid "$_distro_root";
	} fi

	# Linux mountpoints

	log::info "Mounting /proc" && mount -t proc proc "$_distro_root/proc";
	log::info "Mounting /sys" && mount -t sysfs sys "$_distro_root/sys";
	log::info "Binding /dev" && mount --bind /dev "$_distro_root/dev" && \
		ensure::devNodes;
	if ! mountpoint -q "$_distro_root/dev/shm" 2>/dev/null; then {
		log::info "Creating /dev/shm";
		mkdir -p -m 1777 "$_distro_root/dev/shm" && \
			mount -o rw,nosuid,nodev,mode=1777 -t tmpfs shm "$_distro_root/dev/shm";
	} fi
	if ! mountpoint -q "$_distro_root/dev/pts" 2>/dev/null; then {
		log::info "Creating /dev/pts";
		if mountpoint -q /dev/pts 2>/dev/null; then {
			mount --bind /dev/pts "$_distro_root/dev/pts";
		} else {
			mkdir -p "$_distro_root/dev/pts" && \
				mount -o rw,nosuid,noexec,gid=5,mode=620,ptmxmode=000 \
				-t devpts devpts "$_distro_root/dev/pts";
		} fi
	} fi

	# User mountpoints
	if test -d "$_distro_root/home/axon"; then
		mkdir -p "$_distro_root/home/axon/Common";
		mount --bind /data/linux/common "$_distro_root/home/axon/Common";
	fi

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
	if ! grep -q "^127.0.0.1" "$_distro_root/etc/hosts"; then
		echo '127.0.0.1 localhost' >> "${_distro_root}/etc/hosts";
	fi
 
	# Start chroot shell or components when specified
	if test -n "${COMPONENTS:-}"; then {
		local _component;
		for _component in $COMPONENTS; do {
			case "$_component" in
				ssh)
					log::info "Starting ssh daemon";
					# Configure
					local sshd_config
					sshd_config="$_distro_root/etc/ssh/sshd_config"
					sed -i -E 's/#?PasswordAuthentication .*/PasswordAuthentication yes/g' "${sshd_config}"
					sed -i -E 's/#?PermitRootLogin .*/PermitRootLogin yes/g' "${sshd_config}"
					sed -i -E 's/#?AcceptEnv .*/AcceptEnv LANG/g' "${sshd_config}"
 
					    mkdir -p "$_distro_root/run/sshd" "$_distro_root/var/run/sshd";
					    # generate keys
					    if [ $(ls "${_distro_root}/etc/ssh/" | grep -c key) -eq 0 ]; then
					        chroot::run_prog ssh-keygen -A >/dev/null
					    fi
					    # exec sshd
					    chroot::run_prog sh -c '$(which sshd) -p 22';
				    ;;
			    	x11)
					log::info "Starting X11";
					log::info "Waiting for X11 socket";
					until ps -fA | grep -v grep | grep -q \
						'/x.org.server/.*/xsel'; do {
						sleep 1;
					} done
					CUSER=axon chroot::run_prog sh -c 'DISPLAY=:0 $HOME/.xinitrc &';
			esac
		} done 
#	} else {
#		chroot::run_prog /bin/bash -l || true;
	} fi
}

