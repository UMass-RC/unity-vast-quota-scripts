#!/bin/bash

source config.sh

pi_groups=$(ldapsearch -LLL -H ${LDAP_SERVER} -x -b "${LDAP_PISEARCHBASE}" -s sub "(objectClass=posixGroup)" cn | sed -n 's/^[ \t]*cn:[ \t]*\(.*\)/\1/p')
pi_groups=$(echo $pi_groups | sed -e 's/\s\+/,/g')

existing_quotas=$(curl -u ${VAST_USER}:${VAST_PASS} --insecure -s -X GET "https://${VAST_IP}/api/quotas/" -H "accept: application/json" | jq -r '.[].name')

echo $pi_groups | tr "," "\n" | while read LINE
do
    if echo $existing_quotas | grep -q -w -P "work-${LINE}"; then
        echo "Quota for ${LINE} already exists, skipping..."
    else
        echo "Creating quota/directory for ${LINE}..."
        curl -u ${VAST_USER}:${VAST_PASS} --insecure -s -X POST "https://${VAST_IP}/api/quotas/" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"name\": \"work-${LINE}\", \"path\": \"${QUOTA_WORK_PATH}/${LINE}\", \"hard_limit\": ${QUOTA_WORK_AMOUNT}, \"create_dir\": \"True\" }" > /dev/null

        if [ $? -eq 0 ]; then
            echo "OK"
        else
            echo "FAIL"
        fi

        owner=${LINE#"pi_"}
        echo $owner

        echo "Setting ownership on ${LINE}..."
        chown owner:$LINE ${WORK_MOUNT_PATH}/${LINE}
        if [ $? -eq 0 ]; then
            echo "OK"
        else
            echo "FAIL"
        fi

        echo "Setting permissions on ${LINE}..."
        chmod 770 ${WORK_MOUNT_PATH}/${LINE}
        if [ $? -eq 0 ]; then
            echo "OK"
        else
            echo "FAIL"
        fi
    fi
done