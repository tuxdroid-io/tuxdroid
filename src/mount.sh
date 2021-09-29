function mount::umountTree() {
	local _tree="$1";
	local _mountpoint;
	local _mountdump;
	log::info "Cleanly unmounting if necessary";
	_mountdump="$(mount | grep "$_tree" || true)";
	if test -n "$_mountdump"; then {
		mapfile -t _mountpoints < <(echo "$_mountdump" | awk -F ' on ' '{print $2}' | awk '{print $1}' | tac);

		for _mountpoint in "${_mountpoints[@]}"; do
			if mountpoint -q "$_mountpoint"; then {
				log::info "Unmounting $_mountpoint";
				umount -f "$_mountpoint";
			} fi
		done
	} fi
}


