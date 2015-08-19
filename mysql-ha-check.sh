#!/bin/bash
db_mail_log="/var/log/db/dbmail.log"

mail_from="mymail@mydomain.com"
mail_to="alerts@mydomain.com"

mailScript="smtps_mail_send.sh"

# carica variabili e funzioni per controllare lo stato del cluster DB Percona ed avere una lista dei nodi attivi
. ./mysql-ha.sh

# controlla lo stato degli eventuali nodi che fanno da arbitrator
checkArbServers

if [ ${#DBNODES[@]} -ne ${#nodesOk[@]} -o ${#ARBNODES[@]} -ne ${#arbsOk[@]} ]; then

		message="From: ${mail_from}
To: ${mail_to}
Subject: Rilevata anomalia su DB produzione
"
		missingDB=()
        for DB1 in ${DBNODES[@]}; do
				skip=
				for DB2 in "${nodesOk[@]}"; do
					[[ $DB1 == $DB2 ]] && { skip=1; break; }
				done
				[[ -n $skip ]] || missingDB+=( "$DB1")
		done
        for DB1 in ${ARBNODES[@]}; do
				skip=
				for DB2 in "${arbsOk[@]}"; do
					[[ $DB1 == $DB2 ]] && { skip=1; break; }
				done
				[[ -n $skip ]] || missingDB+=( "$DB1")
		done
		for mDB in "${missingDB[@]}"; do
			message="${message}
Server offline o non raggiungibile: ${mDB}"
		done
		md5_message="$(echo -n "${message}" | /usr/bin/md5sum | /bin/cut -d " " -f 1 | /usr/bin/tr -d '\n')"
		sha256_message="$( echo -n "${message}" | /usr/bin/sha256sum | /bin/cut -d " " -f 1 | /usr/bin/tr -d '\n')"
		[ ! -f "${db_mail_log}" ] && /bin/touch "${db_mail_log}"
		last_md5="$(/usr/bin/head -n1 "${db_mail_log}" | /usr/bin/tr -d '\n' 2>/dev/null)"
		last_sha256="$(/usr/bin/tail -n1 "${db_mail_log}" | /usr/bin/tr -d '\n' 2>/dev/null)"
		if [ "${md5_message}" != "${last_md5}" -o "${sha256_message}" != "${last_sha256}" ]; then
				echo "${message}" | ${mailScript}
				echo "${md5_message}" > "${db_mail_log}"
				echo "${sha256_message}" >> "${db_mail_log}"
		fi
else
		echo "$(echo -n "" | /usr/bin/md5sum | /bin/cut -d " " -f 1 | /usr/bin/tr -d '\n')" > "${db_mail_log}"
		echo "$(echo -n "" | /usr/bin/sha256sum | /bin/cut -d " " -f 1 | /usr/bin/tr -d '\n')" >> "${db_mail_log}"
fi
