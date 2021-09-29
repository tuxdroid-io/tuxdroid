use box::user;
function chroot::run_prog() {
	local _chroot_path=":/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
	local _user_id="0";
	local _userspec="${_user_id}:${_user_id}";

	if test -v CUSER; then {
		if [[ "$CUSER" =~ [Aa-zZ] ]]; then {
			local _get_id;
			_get_id="$(user::get_id "${CUSER}")";
			_userspec="${_get_id}:${_get_id}";
		} else {
			_userspec="$CUSER";
			CUSER="$(user::get_name "$CUSER")";
		} fi
	} fi

	local _user_home && _user_home="$(user::get_home "${CUSER:-"root"}")";

	#unshare --fork --pid \
	#SHELL=/bin/bash
	env -i HOME="$_user_home" PATH="$_chroot_path" TERM=xterm-256color \
		"$(command -v chroot)" --userspec=$_userspec -- "$_distro_root" "$@";
}


