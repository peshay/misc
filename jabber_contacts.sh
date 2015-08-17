#! /bin/bash
#
# $Id: bash.sh 45394 2009-09-21 08:21:09Z ahu $
#
# ==> Usage()
#
# date         who  vers   text
# 2013-Feb-19  ahu  2.0    executes failed sql commands again
# 2010-Aug-10  ahu  1.7    changed sqlcommand creation to be much faster
# 2010-Jul-15  ahu  1.6    ldap server switch if first is not reachable
# 2010-Jul-13  ahu  1.5    removed LDAP group option and made automatic search instead
# 2010-Jul-13  ahu  1.4    groups are now named after apple-group-realname value from ldap
# 2010-Jul-12  ahu  1.3    added option for LDAP groups
# 2010-Jul-05  ahu  1.2    only active users will be added
# 2010-Jul-05  ahu  1.1    added insertion for roster-items
# 2010-Jun-18  ahu  1.0    $prog_cmd introduced

  version="2.0"
 progfile="$0"
 prog_cmd="${0##*/}";
 progname="${prog_cmd%%.*}"
  progdir="${0%/*}"

Error ()   { echo -e >&2 "$progname: $*"; exit 1; }
Warning () { echo -e >&2 "$progname: $*"; }
Hint ()    { echo -e     "$progname: $*"; }

Include () {
    test -s $progdir/$1 && . $progdir/$1 && return 0
    Error "Include(): '$1' not avail or faulty.";
}

#################### Script parameter #################

################### Library modules ###################
### appletalk directory functions
#   Include ~/bin/lib/atalk.shlib
#   Include ~/bin/lib/netatalk.shlib
### DNS functions
#   Include ~/bin/lib/dns.shlib
### OnExit procedure call handling
#   Include ~/bin/lib/onexit.shlib
### Ensures that script runs only once a time
#   Include ~/bin/lib/lockexec.shlib
### Handles a configuration file
#   include ~/bin/lib/conffile.shlib
### logfile handling
#   Include ~/bin/lib/log.shlib
### tmpfile handling
#   Include ~/bin/lib/tmpfile.shlib
### Standard timestamp
#   Include ~/bin/lib/timestamp.shlib
### Wait some seconds
#   Include ~/bin/lib/waitnsec.shlib

################### Usage #############################
Usage () {
    cat <<EOF
$progname: Version $version, $copyright

NAME
    $progname -

SYNOPSIS
    $progname [options] {args...}

DESCRIPTION
    This script is to delete the users contacts list
    of a jabber2 (iChat) server and rebuild them from a Open Directory.
    So every active user, will have a contact list with
    the list of specific groups from the LDAP with all users
    like in LDAP.
OPTIONS
    -v          Version
    -h          Help

REQUIREMENTS
CONFIGURATION
EXAMPLES
FILES
SEE ALSO

AUTHORS
    Andreas Hubert

BUGS
    Needs bash(1), developed with bash-3.2.48(1)

$copyright
EOF
    exit 0
}

#################### Functions ########################

#################### Commandline ######################
OPTERR=0                                # suppress error messages
OPTIND=1
while getopts ":vh" opt "$@"; do
    case $opt in
        #g)  groups="$OPTARG $groups" ;;
        v)  echo "$progname, version $version"; exit;;
        h)  Usage;;
        *)  Error "unknown option or missing arg at '-$OPTARG'.";;
    esac
done
shift $((OPTIND-1))                     # remove option from commandline
#test -z "$1" && Error "args missing."

#################### And action ;-) ###################

database=/private/var/jabberd/sqlite/jabberd2.db

ldapurl=ldaps://ldapserver
ldapurl2=ldaps://ldapserver2
base="cn=groups,dc=example,dc=com"
domain="example.com"
# pattern to define groups to grep for
grouppattern="GRP.*"

# check ldap connection, if fails, exit
ldapsearch -x -H $ldapurl -b $base >/dev/null || {
    ldapurl=$ldapurl2
    ldapsearch -x -H $ldapurl -b $base >/dev/null || Error "No LDAP connection."; }

# make group template
# for every contact group you want and do exists in ldap
for lgroup in $(ldapsearch -x -H $ldapurl -b $base | grep "^cn: $grouppattern" | cut -f 2 -d " ")
    do agroup=$(ldapsearch -x -H $ldapurl -b cn=$lgroup,$base | grep apple-group-realname | sed 's/apple-group-realname: //g')
    # get every member of a group
    for member in $(ldapsearch -x -H $ldapurl -b cn=$lgroup,$base | grep memberUid | cut -d " " -f 2)
        # create sql commands with lists owner, members, group assignement
         do sqlite3 -line $database 'select "collection-owner" from active' | cut -d " " -f 3 | grep "$member@" >/dev/null && (
            echo "sqlite3 -line $database 'insert into \"roster-groups\" (\"collection-owner\", \"jid\", \"group\") values (\"changeme\", \"$member@$domain,\", \"$agroup\")'" >> sqlcommand-list.sh
            echo "sqlite3 -line $database 'insert into \"roster-items\" (\"collection-owner\", \"jid\", \"to\", \"from\", \"ask\") values (\"changeme\", \"$member@$domain\", 1, 1, 0)'" >> sqlcommand-list.sh)
    done
done

# get every active user in jabber
for owner in $(sqlite3 -line $database 'select "collection-owner" from active' | cut -d " " -f 3)
    do eval sed 's/changeme/$owner/g' sqlcommand-list.sh >> sqlcommand.sh
done

# clean roster-groups from database
sqlite3 -line $database 'delete from "roster-groups" where "jid" like "%@$domain"'
sqlite3 -line $database 'delete from "roster-items" where "jid" like "%@$domain"'
# refresh the roster-groups
# execute till you have no errors
while read sql_command; do
    eval $sql_command || echo $sql_command >> sqlcommand-fails1.sh
done < sqlcommand.sh 2>/dev/null

counter=1
while :; do
    while read sql_command; do
        eval $sql_command || echo $sql_command >> sqlcommand-fails$[$counter+1].sh
    done < sqlcommand-fails$counter.sh || break
    counter=$[$counter+1]
done
# delete old files
rm sqlcommand*

# Local Variables:
# mode:                 shell-script
# mode:                 font-lock
# comment-column:       40
# tab-width:            8
# End:
