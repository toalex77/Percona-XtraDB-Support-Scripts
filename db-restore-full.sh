#!/bin/bash
MYSQL_ADMIN="/usr/bin/mysqladmin"

if [ "$( ${MYSQL_ADMIN} -h localhost ping 2>&1 > /dev/null ; echo "$?" )" -eq 0 ]; then
	echo "Errore: il servizio MySQL va prima arrestato."
	exit 1
fi

status=0
BASE_DIR="/backup"
if [ $# -gt 0 -a -n "$1" ]; then
	BACKUP_DIR="$1"
else
	if [ "$( /bin/ls -1d "${BASE_DIR}/"*/ 2>/dev/null | /usr/bin/wc -l )" -ne "0" ]; then
		BACKUP_DIR="$( /bin/basename $( /bin/ls -1d "${BASE_DIR}/"*/ | /bin/sort -nr | /usr/bin/head -n1 ) )"
	else
		status=1
		echo "Errore: nessun backup disponibile."
	fi
fi
BACKUP_CMD="/usr/bin/innobackupex"
BACKUP_LOG_DIR="/var/log/dbbackup"

if [ ${status} -eq 0 ]; then
	[ ! -d "${BACKUP_LOG_DIR}" ] && /bin/mkdir -p "${BACKUP_LOG_DIR}"

	if [ -d "${BASE_DIR}/${BACKUP_DIR}" ]; then

		[ ! -f "${BACKUP_LOG_DIR}/full_${BACKUP_DIR}_restore.log" ] && /bin/touch "${BACKUP_LOG_DIR}/full_${BACKUP_DIR}_restore.log"
		while true; do
			read -p "Procedere con il restore del backup ${BACKUP_DIR}? (Si/No) " ans
			case $ans in
				[Ss]* )
					${BACKUP_CMD} --copy-back ${BACKUP_DIR}
					status=$?
					break;;
				[Nn]* )
					echo "Restore annullato dall'utente."
					exit 1;;
				* ) echo "Rispondere con si o no.";;
			esac
		done

	else
		status=1
		echo "Errore: ${BASE_DIR}/${BACKUP_DIR} inesistente."
	fi
fi
exit ${status}
