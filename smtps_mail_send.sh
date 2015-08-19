#!/bin/bash
export LANG=en_US.UTF-8
. ./smtps_mail_conf.sh
from="mymail@mydomain.com"
cat /dev/stdin | tr -d '\r' | /bin/mailx -S ssl-verify=ignore -S smtp-auth=login -S smtp="${smtpsHost}" -S from="${from}" -S smtp-auth-user="${smtpsUser}" -S smtp-auth-password="${smtpsPass}" -S nss-config-dir=/etc/pki/nssdb -t "$@"
