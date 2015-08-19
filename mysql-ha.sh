#!/bin/bash

. ./mysql-ha.conf.sh

checkDBServers (){
	local DB
	nodesOk=()
	nodesKO=()
	for DB in "${DBNODES[@]}"; do
		/usr/bin/mysqladmin -h ${DB} ping > /dev/null 2>&1 && nodesOk+=( "${DB}" ) || nodesKO+=( "${DB}" )
	done
}

checkArbServers (){
	local Arb
	arbsOk=()
	arbsKO=()
	for Arb in "${ARBNODES[@]}"; do
		[ "$( /usr/bin/telnet "${Arb}" 4567 2>/dev/null < /dev/null | /usr/bin/wc -l )" -gt 1 ] && arbsOk+=( "${Arb}" ) || arbsKO+=( "${Arb}" )
	done
}

pickRandomDB (){
	pickRandomDB=$(( ( $RANDOM % ${#nodesOk[@]} ) ))
	DBNODE=${nodesOk[${pickRandomDB}]}
}

if [ -n "${addDB}" ]; then
	DBNODES+=( "${addDB[@]}" )
fi

if [ -n "${addARB}" ]; then
	ARBNODES+=( "${addARB[@]}" )
fi

nodesOk=()
arbsOk=()

nodesKO=()
arbsKO=()

DBNODE=

checkDBServers
