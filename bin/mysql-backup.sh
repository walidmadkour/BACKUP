#!/bin/bash
set -e

MyHOST="localhost"  # Hostname
touch /tmp/mbkp
# If cleanup is set to "1", backups older than $OLDERTHAN days will be deleted!
CLEANUP=1
OLDERTHAN=30

# Backup Dest directory
DEST="/home/backup-database"

# Directory, where a copy of the "latest" dumps will be stored
LATEST=$DEST/latest

# Get hostname
HOST="$(hostname)"

# Get data in dd-mm-yyyy format
NOW="$(date +"%Y-%m-%d")"

# DO NOT BACKUP these databases (separate database names by space)
EXCLUDE=""


### Libraries ###
MYSQL="$(which mysql)"
if [ -z "$MYSQL" ]; then
    echo "Error: MYSQL not found"
    exit 1
fi
MYSQLDUMP="$(which mysqldump)"
if [ -z "$MYSQLDUMP" ]; then
    echo "Error: MYSQLDUMP not found"
    exit 1
fi
CHOWN="$(which chown)"
if [ -z "$CHOWN" ]; then
    echo "Error: CHOWN not found"
    exit 1
fi
CHMOD="$(which chmod)"
if [ -z "$CHMOD" ]; then
    echo "Error: CHMOD not found"
    exit 1
fi
GZIP="$(which lrzip)"
if [ -z "$GZIP" ]; then
    echo "Error: GZIP not found"
    exit 1
fi
CP="$(which cp)"
if [ -z "$CP" ]; then
    echo "Error: CP not found"
    exit 1
fi

[ ! -d $DEST ] && mkdir -p $DEST || :
[ ! -d $LATEST ] && mkdir -p $LATEST || :

# Only root can access it!
#$CHOWN 0.0 -R $DEST
#$CHMOD 0600 $DEST

# Get a list of all databases available
DBS="$($MYSQL -uroot -p...mysql-password....  -Bse 'show databases')"
#change -p...mysql-password.... with myql password EX: -padminmysql 
echo "$DBS" > /tmp/dbs
# start dumping databases
for db in $DBS
do
    skipdb=-1
    if [ "$EXCLUDE" != "" ];
    then
        for i in $EXCLUDE
        do
            [ "$db" == "$i" ] && skipdb=1 || :
        done
    fi

    if [ "$skipdb" == "-1" ] ; then
            FILE="$DEST/$db.$HOST.$NOW.lrz"
            # do all in one job in pipe,
            # connect to mysql using mysqldump for select mysql database
            # and pipe it out to gz file in backup dir :)
        $MYSQLDUMP -uroot -p...mysql-password....  --add-drop-database -ca --flush-privileges --single-transaction -B $db | $GZIP -z -L 9 > $FILE
        $CP $FILE "$LATEST/$db.$HOST.latest.lrz"
    fi
done

# Remove files older than x days if cleanup is activated
if [ $CLEANUP == 1 ]; then
    find $DEST/ -name "*.lrz" -type f -mtime +$OLDERTHAN -delete
fi
touch /tmp/mbkp1
touch /tmp/mbkp2
