#!/bin/zsh

_jack_connected_ports() {
	local -a ports

	jack_lsp -c | awk "
		BEGIN     { cur = \"\"; }
		/^[^ \t]/ { cur = \"\"; }
		/^$1/     { cur = \$0; }
		/^ +/     {
			if( !cur ) next;
			gsub(/^ +/, \"\", \$0);
			printf(\"%s\n\", \$0);
		}"
}

_jack_ports_of_type() {
	if [ $1 -ne 0 ]; then
		# input
		jack_lsp -p | awk '
			BEGIN     { cur = ""; }
			/^[^ \t]/ { cur = $0; }
			/input/   { printf("%s\n", cur); }'
	else
		# output
		jack_lsp -p | awk '
			BEGIN     { cur = ""; }
			/^[^ \t]/ { cur = $0; }
			/output/  { printf("%s\n", cur); }'
	fi
}

_jack_connect_cpl() {
	local -a ports line
	local port port_type

	read -cA line
	IFS=$'\n\n'

	case ${#line} in
		2)
			reply=(`jack_lsp`)
			;;

		3)
			port=`echo $line[2] | sed 's/[\\"]//g'`

			# determine the port type (0 if input, 1 if output)
			jack_lsp -p | grep -A1 $line[2] | tail -1 | grep output >/dev/null 2>/dev/null
			port_type=$?

			# construct a complement of all ports to which we can connect
			# and ports to which we're already connected
			reply=($((for PORT in `_jack_connected_ports $port` `_jack_ports_of_type $((! $port_type))`;
				do echo $PORT;
			done) | sort | uniq -u))
			;;

		default)
			reply=()
			;;
	esac

	unset IFS
}

_jack_disconnect_cpl() {
	local -a line ports
	local port

	read -cA line
	IFS=$'\n\n'

	case ${#line} in
		2)
			# find all ports that are connected to something
			reply=(`jack_lsp -c | awk '
				BEGIN     { cur = ""; }
				/^[^ \t]/ { cur = $0; }
				/^[ \t]+/ {
					if( !cur ) next;
					printf("%s\n", cur);
					cur = ""; }'`)
			;;

		3)
			port=`echo $line[2] | sed 's/[\\"]//g'`
			reply=(`_jack_connected_ports $port`)
			;;

		default)
			reply=()
			;;
	esac

	unset IFS
}

compctl -K _jack_connect_cpl jack_connect
compctl -K _jack_disconnect_cpl jack_disconnect
