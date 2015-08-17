#! /usr/bin/env python
# This script is to read from a Active Directory Server
# to get sAMAccountName and objectGUID to transform them
# to SQL statements for a specific user table
import ldap
import getpass
import uuid

LDAPURL = "ldaps://ldapserver"
DOMAIN = "example.com"
# ask for login credentials
USER = raw_input("Username:")
PASS = getpass.getpass("Password for " + USER + ":")
USERNAME = USER + "@" + DOMAIN

l = ldap.initialize(LDAPURL)
try:
    l.protocol_version = ldap.VERSION3
    l.set_option(ldap.OPT_REFERRALS, 0)

    bind = l.simple_bind_s(USERNAME, PASS)

    base = "cn=Users,dc=example,dc=com"
    criteria = "(cn=*)"
    attributes = ['sAMAccountName', 'ObjectGUID']
    result = l.search_s(base, ldap.SCOPE_SUBTREE, criteria, attributes)
    results = [entry for dn, entry in result if isinstance(entry, dict)]
finally:
    l.unbind()

for item in results:
    uobjectGUID = uuid.UUID(bytes=item['objectGUID'][0])
    objectGUID = str(uobjectGUID).upper()
    objectGUIDplain = objectGUID.translate(None, '-')
    sAMAccountName = item.get('sAMAccountName')
    print "update users set id_extern = '" + objectGUIDplain + "' where login = " + str(sAMAccountName).strip('[]') + ";"


