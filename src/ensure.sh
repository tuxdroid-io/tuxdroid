function ensure::devNodes() {
	if [ ! -e "/dev/fd" ]; then
		ln -s /proc/self/fd /dev/
	fi
        if [ ! -e "/dev/stdin" ]; then
		ln -s /proc/self/fd/0 /dev/stdin
	fi
	if [ ! -e "/dev/stdout" ]; then
		ln -s /proc/self/fd/1 /dev/stdout
	fi
        if [ ! -e "/dev/stderr" ]; then
		ln -s /proc/self/fd/2 /dev/stderr
        fi
        if [ ! -e "/dev/tty0" ]; then
		ln -s /dev/null /dev/tty0
        fi
        if [ ! -e "/dev/net/tun" ]; then
		mkdir -p /dev/net
		mknod /dev/net/tun c 10 200
        fi
}

