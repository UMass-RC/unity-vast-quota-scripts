#!/bin/bash

source config.sh

users=$(ldapsearch -LLL -H ${LDAP_SERVER} -x -b "${LDAP_USERSEARCHBASE}" -s sub "(objectClass=posixAccount)" cn | sed -n 's/^[ \t]*cn:[ \t]*\(.*\)/\1/p')
users=$(echo $users | sed -e 's/\s\+/,/g')

existing=$(curl -u ${VAST_USER}:${VAST_PASS} --insecure -s -X GET "https://${VAST_IP}/api/quotas/" -H "accept: application/json" | jq -r '.[] | "\(.id)|\(.name)"')

echo $existing | tr " " "\n" | while read LINE
do
    IFS='|'
    read -a jsonline <<< "$LINE"
    quota_id=${jsonline[0]}
    quota_name=${jsonline[1]}
    echo $quota_id:$quota_name

    if [[ "$quota_name" =~ ^home.* ]]; then
        echo "Found home quota, updaing..."
	curl -u ${VAST_USER}:${VAST_PASS} --insecure -s -X PATCH "https://${VAST_IP}/api/quotas/${quota_id}/" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"hard_limit\": ${QUOTA_HOME_AMOUNT} }"
    fi
done
