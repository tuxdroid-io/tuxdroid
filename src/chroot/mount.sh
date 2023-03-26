function mount::umountTree() {
	local _tree="$1";
	local _mountpoint;
	local _mountdump;
	log::info "Cleanly unmounting if necessary";
	_mountdump="$(grep "$_tree" /proc/mounts || true)";
	if test -n "$_mountdump"; then {
		mapfile -t _mountpoints < <(echo "$_mountdump" | awk '{print $2}' | grep '^/.*' | tac);

		for _mountpoint in "${_mountpoints[@]}"; do
			while mountpoint -q "$_mountpoint" \
			|| grep -q " ${_mountpoint} " /proc/mounts; do {
				log::info "Unmounting $_mountpoint";
				umount -df "$_mountpoint";
			} done
		done
		while grep -q "$_tree" /proc/mounts; do {
			umount -df "$_tree";
		} done
	} fi
}


