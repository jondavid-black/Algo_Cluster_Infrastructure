var_multiple_time_servers="0.rhel.pool.ntp.org,1.rhel.pool.ntp.org,2.rhel.pool.ntp.org,3.rhel.pool.ntp.org"

# Invoke the function without args, so its body is substituded right here.
# Function ensures that the ntp/chrony config file contains valid server entries
# $1: Path to the config file
# $2: Comma-separated list of servers
function ensure_there_are_servers_in_ntp_compatible_config_file {
	# If invoked with no arguments, exit. This is an intentional behavior.
	[ $# -gt 1 ] || return 0
	[ $# = 2 ] || die "$0 requires zero or exactly two arguments"
	local _config_file="$1" _servers_list="$2"
	if ! grep -q '#[[:space:]]*server' "$_config_file"; then
		for server in $(echo "$_servers_list" | tr ',' '\n') ; do
			printf '\nserver %s iburst' "$server" >> "$_config_file"
		done
	else
		sed -i 's/#[ \t]*server/server/g' "$_config_file"
	fi
}

ensure_there_are_servers_in_ntp_compatible_config_file

config_file="/etc/ntp.conf"
/usr/sbin/pidof ntpd || config_file="/etc/chrony.conf"

[ "$(grep -c '^server' "$config_file")" -gt 1 ] || ensure_there_are_servers_in_ntp_compatible_config_file "$config_file" "$var_multiple_time_servers"
