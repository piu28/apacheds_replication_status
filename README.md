# apacheds_replication_status
The script will be helpful to get the replication status between two ApacheDS Servers.

## Setup Details:
- Two Apache Directory ApacheDS EC2 Servers (Redhat) with master-master replication enabled running with version 2.0.0.AM24.
- FROM_EMAIL address is verified in AWS SES in region us-east-1.
- The Directory Structure is as follows:
  - o=DOMAIN
    - ou=WEB
      - ou=USER
        - cn=user1
        - cn=user2
        - cn=user3

## Usage
- Clone the Repo
- Ensure LDAP Utilities are installed on the server from where the script will be executed since the script will execute ldapsearch on ApacheDS.
- Replace the required variables in the script such as LDAP Master IPs, LDAP Bind Username/Password, FROM/TO Email addresses etc.
- Execute the script: sh ldap_replication_script.sh

## Cron
I have scheduled the script using CronJob. The following command can be used in crontab:
### */10 * * * * sh /opt/ldap_replication_script/ldap_replication_script.sh >> /opt/ldap_replication_script/ldap_status 2>&1
The script wil execute every 10 minutes to check for the replication status. If the user count doesn't match in both master servers, the noification will be sent to TO_EMAIL address.
![Ldap Replication Alert]("repl.jpg")
