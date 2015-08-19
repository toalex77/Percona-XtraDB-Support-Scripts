#!/bin/bash

. ./mysql/mysql-ha.sh

checkArbServers

grastate='/var/lib/mysql/grastate.dat'

seqno=0
bootstrapNode=
nodeHostname="$(/bin/hostname)"

startNode() {
	if [ $# -gt 1 ]; then
		service="$1"
		node="$2"
		mode="start"
		if [ "${service}" == "bootstrap" ]; then
			mode="bootstrap-pxc"
			service="mysql"
		fi
		
		command="/bin/sh -c"
		[ "${node}" != "${nodeHostname}" ] && command="/usr/bin/ssh root@'${node}'"
		command+=" '/sbin/service "${service}" "${mode}" > /dev/null 2>&1 ; echo -n \"\$?\"'"
		echo "Avvio ${node}"
		startStatus="$( eval "${command}" )"
		if [ -n "${startStatus}" -a ${startStatus} -ne 0 ]; then
			echo "Errore avvio su nodo ${node}."
			exit 1
		fi
	fi
	}

if [ ${#nodesKO[@]} -gt 0 ]; then
	needBootstrap=0
	if [ ${#nodesOk} -eq 0 ]; then
		needBootstrap=1
		for node in "${nodesKO[@]}"; do
			nodeSeqno="$(/usr/bin/ssh root@"${node}" "/bin/cat "${grastate}" | /bin/sed -ne 's/seqno:[[:space:]]*\(.*\)/\1/p'")"
			if [ "${nodeSeqno}" -gt "${seqno}" ]; then
				bootstrapNode="${node}"
				seqno="${nodeSeqno}"
			fi
		done

		if [ -n "${bootstrapNode}" ]; then
			echo "Bootstrap."
			startNode "bootstrap" "${bootstrapNode}"
			needBootstrap=0
		else
			echo "Impossibile stabilire come effettuare il bootstrap."
			echo "Tentativo di avvio normale di tutti i nodi in parallelo."
		fi
		echo
	fi
	
	echo "Avvio MySQL."
	for node in "${nodesKO[@]}"; do
		if [ "${node}" != "${bootstrapNode}" ]; then
			if [ ${needBootstrap} -eq 0 ]; then
				startNode "mysql" "$node"
			else
				startNode "mysql" "$node" &
				startPID=$!
			fi
		fi
	done
	if [ ${needBootstrap} -ne 0 ]; then
		wait
	fi
	echo
fi
if [ ${#arbsKO[@]} -gt 0 ]; then
	echo "Avvio arbitrator."
	for node in ${arbsKO[@]}; do
		startNode "garb" "${node}"
	done
	echo
fi
