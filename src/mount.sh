function mount::umountTree() {
	local _tree="$1";
	local _mountpoint;
	local _mountdump;
	_mountdump="$(mount | grep "$_tree" || true)";
	if test -n "$_mountdump"; then {
		while read -r _mountpoint; do
			if mountpoint -q "$_mountpoint"; then {
				umount -fd "$_mountpoint";
			} fi
		done < <(echo "$_mountdump" | awk -F ' on ' '{print $2}' | awk '{print $1}' | tac)
	} fi
}


