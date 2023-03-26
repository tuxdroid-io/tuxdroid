function chroot::stop() {
	# Kill all running programs under chroot
	local _chroot_pids _pid;
	mapfile -t _chroot_pids < <(busybox lsof | grep "$_distro_root" \
		| awk '{print $1}' | uniq || true);

	for _pid in "${_chroot_pids[@]}"; do {
		log::info "Killing $_pid";
		kill -9 "$_pid";
	} done

	# Unload all mountpoints
	mount::umountTree "$_distro_root";

#	if ! mountpoint -q /dev/shm 2>/dev/null; then {
#		rmdir /dev/shm 2>/dev/null || true;
#	} fi
}
