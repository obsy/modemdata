# Shared AT transport for Modemdata and QModem. Source before calling md_at.
md_at() (
	port=$1
	atcmd=$2
	[ -n "$port" ] && [ -n "$atcmd" ] || exit 2
	# Match QModem's per-port lock. Keep it in a subshell so the descriptor
	# is released on every exit, including a failed command.
	port_key=$(printf '%s' "$port" | tr -c 'A-Za-z0-9_' '_')
	mkdir -p /var/lock || exit 1
	exec 6>"/var/lock/qmodem-at-$port_key.lock" || exit 1
	flock -x 6 || exit 1

	# Never open a second reader on a port owned by the AT daemon. Failure
	# to inspect/use that daemon must not trigger an unsafe direct retry.
	daemon=""
	if command -v ubus >/dev/null 2>&1; then
		daemon=$(ubus list at-daemon 2>/dev/null) || exit 1
	fi
	if [ "$daemon" = "at-daemon" ]; then
		# Route even previously-unopened ports through the daemon: checking
		# its ownership list then opening directly has a check/open race.
		command -v tom_modem >/dev/null 2>&1 || exit 1
		tom_modem -u -d "$port" -o a -c "$atcmd"
		exit $?
	fi
	if command -v tom_modem >/dev/null 2>&1; then
		tom_modem -d "$port" -o a -c "$atcmd"
	else
		sms_tool -D -d "$port" at "$atcmd"
	fi
)

# Quectel identity commands can return either plain or prefixed values.
# Ignore echoes, terminal results and unrelated URCs rather than assigning
# the next arbitrary line to a modem/SIM field (as the gcom collector does).
md_identity() (
	response=$(md_at "$DEVICE" "$1") || exit $?
	printf '%s\n' "$response" | tr -d '\r' | awk -v prefix="$2" -v kind="${3:-text}" '
		{ sub(/^[[:space:]]+/, ""); sub(/[[:space:]]+$/, "") }
		!length || /^AT/ || /^(OK|ERROR|RDY|APP RDY|SMS Ready|Call Ready|PB DONE|RING|NO CARRIER|NO DIALTONE|BUSY|CONNECT)$/ { next }
		index($0, prefix) == 1 { sub(/^[^:]*:[[:space:]]*/, "") }
		/^[+^#]/ { next }
		{
			gsub(/"/, "")
			# ICCIDs may have a trailing hexadecimal F padding nibble.
			if (kind == "iccid" && $0 !~ /^[0-9]+[Ff]?$/) next
			if (kind != "text" && kind != "iccid" && $0 !~ /^[0-9]+$/) next
			if (kind == "imei" && (length < 15 || length > 16)) next
			if (kind == "imsi" && (length < 5 || length > 15)) next
			if (kind == "iccid" && (length < 18 || length > 22)) next
			print; exit
		}
	'
)
