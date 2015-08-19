#!/bin/bash
export LANG=en_US.UTF-8
from="mymail@mydomain.com"
smtpsHost="smtps://mail.mydomain.com:465"
smtpsUser="smtpaccount@mydomain.com"
smtpsPass="supersecretpassword"
cat /dev/stdin | tr -d '\r' | /bin/mailx -S ssl-verify=ignore -S smtp-auth=login -S smtp="${smtpsHost}" -S from="${from}" -S smtp-auth-user="${smtpsUser}" -S smtp-auth-password="${smtpsPass}" -S nss-config-dir=/etc/pki/nssdb -t "$@"
