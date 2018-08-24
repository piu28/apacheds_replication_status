#!/bin/bash
NONE='\033[00m'
DATE=`date '+%Y-%m-%d-%H:%M:%S'`

MASTER01="10.xx.xxx.xxx"
MASTER02="10.xxx.xx.xxx"

FROM_EMAIL="noreply@domain.com"
TO_EMAIL="user@domain.com"

LDAP_BIND_USER="uid=admin,ou=system"
LDAP_BIND_PWD="xxxxxx"
SEARCH_BASE="ou=USER,ou=WEB,o=DOMAIN"

mkdir -p /opt/ldap_replication_script

FILE01="/opt/ldap_replication_script/master01.txt"
FILE02="/opt/ldap_replication_script/master02.txt"
CONNMESSAGE01="/opt/ldap_replication_script/masterconn_alert01.json"
CONNMESSAGE02="/opt/ldap_replication_script/masterconn_alert02.json"
REPLMESSAGE="/opt/ldap_replication_script/replication_alert.json"
SORTED_USERS_FILE01="/opt/ldap_replication_script/sorted_users01.txt"
SORTED_USERS_FILE02="/opt/ldap_replication_script/sorted_users02.txt"

timeout 60 ldapsearch -D ${LDAP_BIND_USER} -w ${LDAP_BIND_PWD} -p 10389 -h ${MASTER01} -b ${SEARCH_BASE} | grep -E 'cn:|numEntries:' > $FILE01
EXIT_STATUS=$?

if [ $EXIT_STATUS != 0 ]
then
echo -e "\e[32m${DATE} Unable to execute ldapsearch command.${NONE}"
echo "{
  \"Subject\": {
    \"Data\": \"LDAP Connection Alert\",
    \"Charset\": \"UTF-8\"
  },
  \"Body\": {
    \"Text\": {
      \"Data\": \"Alert!! Ldapsearch command didnot execute successfully on server '${MASTER01}'. \nPossible Reason: Unable to connect to LdapServer. \nSolution: Check ApacheDS Service Status.\",
      \"Charset\": \"UTF-8\"
    }
  }
}" > ${CONNMESSAGE01}
aws ses send-email --destination ToAddresses=${TO_EMAIL} --from ${FROM_EMAIL} --message file://${CONNMESSAGE01} --region us-east-1
else

timeout 60 ldapsearch -D ${LDAP_BIND_USER} -w ${LDAP_BIND_PWD} -p 10389 -h ${MASTER02} -b ${SEARCH_BASE} | grep -E 'cn:|numEntries:' > $FILE02
EXIT_STATUS=$?

if [ $EXIT_STATUS != 0 ]
then
echo -e "\e[32m${DATE} Unable to execute ldapsearch command.${NONE}"
echo "{
  \"Subject\": {
    \"Data\": \"LDAP Connection Alert\",
    \"Charset\": \"UTF-8\"
  },
  \"Body\": {
    \"Text\": {
      \"Data\": \"Alert!! Ldapsearch command didnot execute successfully on server '${MASTER02}'. \nPossible Reason: Unable to connect to LdapServer. \nSolution: Check ApacheDS Service Status.\",
      \"Charset\": \"UTF-8\"
    }
  }
}" > ${CONNMESSAGE02}
aws ses send-email --destination ToAddresses=${TO_EMAIL} --from ${FROM_EMAIL} --message file://${CONNMESSAGE02} --region us-east-1

else
NUMENTRIES1=`cat $FILE01 | grep numEntries: | awk '{print $3}'`
NUMENTRIES2=`cat $FILE02 | grep numEntries: | awk '{print $3}'`

if [[ "${NUMENTRIES1}" == "${NUMENTRIES2}" ]]; then
echo -e "\e[32m${DATE} Replication is in sync.${NONE}"

else
echo -e "\e[31m${DATE} Replication is not in sync. Sending Alert.....${NONE}"
cat $FILE01 | grep cn: | sort -n -k 2 > ${SORTED_USERS_FILE01}
cat $FILE02 | grep cn: | sort -n -k 2 > ${SORTED_USERS_FILE02}
USERS1=`diff -s $SORTED_USERS_FILE01 $SORTED_USERS_FILE02 | grep cn: | grep '<' | tr -d '< ' | awk 'NR%1{printf $0;next;}1' | paste -s -d, -`
USERS2=`diff -s $SORTED_USERS_FILE01 $SORTED_USERS_FILE02 | grep cn: | grep '>' | tr -d '> ' | awk 'NR%1{printf $0;next;}1' | paste -s -d,  -`
echo "{
  \"Subject\": {
    \"Data\": \"LDAP Replication Alert\",
    \"Charset\": \"UTF-8\"
  },
  \"Body\": {
    \"Text\": {
      \"Data\": \"Alert!! Ldap Replication not in Sync.\n\nTotal Entries: \nnumEntries in ${MASTER01}: ${NUMENTRIES1} \nnumEntries in ${MASTER02}: ${NUMENTRIES2} \n\nUser Difference in Both Servers: \nUsers in ${MASTER01}: ${USERS1} \nUsers in ${MASTER02}: ${USERS2}\",
      \"Charset\": \"UTF-8\"
    }
  }
}" > ${REPLMESSAGE}
aws ses send-email --destination ToAddresses=${TO_EMAIL} --from ${FROM_EMAIL} --message file://${REPLMESSAGE} --region us-east-1
fi
fi
fi
