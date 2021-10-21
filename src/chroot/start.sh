use box::ensure;
use box::mount;
use box::user;
use run_prog;
use stop;

function chroot::start() {
	
	echo "Starting the container ...";

	# Make sure the container is stopped
	chroot::stop;

	# Remount self with custom options
	if grep -qE '/dev/block/.* /data .*nosuid|/dev/block/.* /data .*nodev|/dev/block/.* /data .*noexec' /proc/mounts; then {
		mount -oremount,suid,dev,exec /data || { log::warn "Tried to remount as suid but failed, so continuing..." && {
		mount --bind "$_distro_root" "$_distro_root";
		mount -o remount,dev,exec,suid "$_distro_root";

	  }
 	 }
	} fi

	# Dry run stuff
	if test "${DRY_RUN:-}" == true; then {
		log::info "Initializing dry-run mode, happy experimenting!";
		local _overlay_root="${_distro_root%/*}/.tuxdroid_overlay";
		rm -rf "$_overlay_root";
		mkdir -p -m 0755 "$_overlay_root/worker" "$_overlay_root/upper";
		mount -t overlay overlay -o \
			lowerdir="$_distro_root",upperdir="$_overlay_root/upper",workdir="$_overlay_root/worker" "$_distro_root";

	} fi


	#mount -o bind "$_distro_source" "$_distro_root";
	#mount -o remount,dev,exec,suid "$_distro_root";




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

	#if ! mountpoint -q "$_distro_root/tmp"; then {
		rm -rf "$_distro_root/tmp";
		mkdir -m 0777 -p "$_distro_root/tmp";
		#mount -t tmpfs tmpfs -omode=0777,nosuid,nodev "$_distro_root/tmp";
		chmod +t "$_distro_root/tmp";
	#} fi

	# User mountpoints
	if test -d "$_distro_root/home/axon"; then
		mkdir -p "$_distro_root/home/axon/Common";
		mount --bind /data/linux/common "$_distro_root/home/axon/Common";
	fi


	# DNS
	_resolv_conf="$_distro_root/etc/resolv.conf"
	rm "$_resolv_conf" || true
	for _dns in "1.1.1.1" "1.0.0.1"; do
		echo "nameserver $_dns" >> "$_resolv_conf"
	done
	if ! grep -q "^127.0.0.1" "$_distro_root/etc/hosts"; then
		echo '127.0.0.1 localhost' >> "${_distro_root}/etc/hosts";
	fi

	function dbus_daemon_start() {
		log::info "Starting dbus system daemon";
		rm -rf "$_distro_root/run/dbus" && mkdir -p -m 0755 "$_distro_root/run/dbus";
		CUSER=root chroot::run_prog dbus-daemon --system --fork;
	}
 
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
					dbus_daemon_start;
					log::info "Starting X11";
					log::info "Waiting for X11 socket";
					until ps -fA | grep -v grep | grep -q \
						'/x.org.server/.*/xsel'; do {
						sleep 1;
					} done
					# Note: No idea why XSDL spawns it's own xsel
					#pkill -9 xsel;
					#if test -e "$_distro_root/usr/bin/tmux"; then
					CUSER=axon chroot::run_prog dtach -n /tmp/tuxdroid_x11.sock -Ez sh -c '{ cd && chmod +x .xinitrc && exec $PWD/.xinitrc 2>&1; } > /tmp/dbus.log 2>&1';

					#{ CUSER=axon chroot::run_prog sh -i -c 'cd && chmod +x .xinitrc && exec $PWD/.xinitrc &' 2>&1; } > "$_distro_root$(user::get_home axon)/dbus.log" 2>&1;
				;;
				vnc)
					dbus_daemon_start;
					log::info "Starting VNC";
					CUSER=axon chroot::run_prog dtach -n /tmp/tuxdroid_vnc.sock -Ez sh -c '{ cd && chmod +x .xinitrc && exec vncserver :0 2>&1; } > /tmp/vncserver.log 2>&1'

				;;
				fb)
					dbus_daemon_start;
					log::info "Starting framebuffer";
					sync; sync; sync;

					#log::info "Waiting for xinit a bit"; 
					#(sync; sync; sync) & sleep 5;

function fbref() {
	local fbrotate=/sys/class/graphics/fb0/rotate;
	local pid_file="$_distro_root/tmp/xsession.pid"
        touch "${pid_file}"
        chmod 666 "${pid_file}"
        while [ -e "${pid_file}" ]
        do
            echo 0 > "${fbrotate}"
            sleep 0.01
        done
}
					true 'CUSER=root chroot::run_prog fbrefresh &'
					fbref & read
					true 'set +eETu;
					(
						exec {sleep_fd}<> <(:)
						while echo 0 > /sys/class/graphics/fb0/rotate || true; do read -t 0.035 -u $sleep_fd; done
					) & disown;'
					CUSER=axon chroot::run_prog dtach -n /tmp/xinit.sock -Ez sh -l -c '{ xinit -- :0 -dpi 100 -sharevts vt0 2>&1; } >/tmp/xinit.log 2>&1';
					#CUSER=axon chroot::run_prog sh -l -c 'xinit -- :0 -dpi 100 -sharevts vt0' &
					
					log::info "Killing surfaceflinger";
					setprop ctl.stop surfaceflinger;
					sleep 10
					#setprop ctl.stop zygote
					while test -e "$_distro_root/tmp/xinit.sock"; do {
						sleep 10;
					} done
					pkill -9 fbrefresh;
					setprop ctl.start surfaceflinger;
			esac
		} done 
#	} else {
#		chroot::run_prog /bin/bash -l || true;
	} fi
}

