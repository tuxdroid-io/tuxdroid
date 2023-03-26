user::get_id() {
	local _user_name="${1%%:*}";
	echo $(grep -m1 "^${_user_name}:" "$_distro_root/etc/passwd" | awk -F: '{print $3}');
}

user::get_name() {
	local _user_id="${1%%:*}";
	echo $(grep -m1 "^.*:.*:${_user_id}" "$_distro_root/etc/passwd" | awk -F: '{print $1}');
}

user::get_home() {
    local _user_name="${1%%:*}";
    if test "$_user_name" == root; then {
	echo "/root";
    } else {
	echo "/home/$_user_name";
	} fi
}

user::get_shell() {
    local _user_name="$1";
    echo $(grep -m1 "^${_user_name}:" "${_distro_root}/etc/passwd" | awk -F: '{print $7}');
}

