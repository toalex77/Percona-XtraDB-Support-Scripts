#!/bin/bash
status=0
BASE_DIR="/backup"
if [ $# -gt 0 -a -n "$1" ]; then
	BACKUP_DIR="$1"
else
	BACKUP_DIR="$(/bin/date +\%Y\%m\%d\%H\%M)"
fi
BACKUP_CMD="/usr/bin/innobackupex"
BACKUP_LOG_DIR="/var/log/dbbackup"
BACKUP_USER="backup"
BACKUP_PASS="supersecretbackuppassword"

[ ! -d "${BACKUP_LOG_DIR}" ] && /bin/mkdir -p "${BACKUP_LOG_DIR}"

if [ -d "${BASE_DIR}/${BACKUP_DIR}" ]; then
	echo "Errore: ${BASE_DIR}/${BACKUP_DIR} già esistente."
	status=1
else

	[ ! -f "${BACKUP_LOG_DIR}/full_${BACKUP_DIR}_create.log" ] && /bin/touch "${BACKUP_LOG_DIR}/full_${BACKUP_DIR}_create.log"

	${BACKUP_CMD} --user="${BACKUP_USER}" --password="${BACKUP_PASS}" --no-timestamp "${BASE_DIR}/${BACKUP_DIR}" 2>&1 | /usr/bin/tee -a "${BACKUP_LOG_DIR}/full_${BACKUP_DIR}_create.log"
	status="$?"
	if [ "${status}" -eq 0 ]; then
		[ ! -f "${BACKUP_LOG_DIR}/full_${BACKUP_DIR}_prepare.log" ] && /bin/touch "${BACKUP_LOG_DIR}/full_${BACKUP_DIR}_prepare.log"
		${BACKUP_CMD} --apply-log "${BASE_DIR}/${BACKUP_DIR}" 2>&1 | /usr/bin/tee -a "${BACKUP_LOG_DIR}/full_${BACKUP_DIR}_prepare.log"
		status="$?"
		if [ "${status}" -ne 0 ]; then
			echo "Errore: preparazione backup fallita (${status})."
		fi
	else
		echo "Errore: creazione backup fallita (${status})."
	fi
fi
exit "${status}"
