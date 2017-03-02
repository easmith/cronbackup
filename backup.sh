#!/bin/bash

# For backups
# @author: Eugene Smith <easmith@mail.ru>
# 
# Cron jobs:
# 15/15 * * * * /PATHTO/backup.sh minutely >> /PATHTO/log.txt 2>&1
# 0 * * * * /PATHTO/backup.sh hourly >> /PATHTO/log.txt 2>&1
# 7 4 * * * /PATHTO/backup.sh daily >> /PATHTO/log.txt 2>&1
# 22 4 * * 0 /PATHTO/backup.sh weekly >> /PATHTO/log.txt 2>&1
# 37 4 1 * * /PATHTO/backup.sh monthly >> /PATHTO/log.txt 2>&1

DATABASE="database_name"
ENCODING="utf8"
DATE=`date +%Y%m%d%H%M%S`
WORKDIR=`dirname $0`

function sqldump ()
{
  mysqldump --defaults-file=$WORKDIR/mysql.conf --single-transaction --dump-date=false --set-charset --default-character-set=$ENCODING $1 --result-file=$2 $DATABASE
}

function dumpAll ()
{
  if [ ! -d "$WORKDIR/$1" ]; then
    mkdir $WORKDIR/$1
  fi
  RESULTFILE=$WORKDIR/$1/$DATE'_schema.sql'
  sqldump '--skip-triggers --no-autocommit --disable-keys --add-drop-table --no-data' $RESULTFILE
  echo $RESULTFILE
  
  RESULTFILE=$WORKDIR/$1/$DATE'_data.sql'
  sqldump '--no-create-info --extended-insert=false --skip-triggers --no-autocommit --disable-keys' $RESULTFILE
  echo $RESULTFILE

  RESULTFILE=$WORKDIR/$1/$DATE'_triggers.sql'
  sqldump '--no-create-info --no-data --extended-insert=false --triggers=true --disable-keys' $RESULTFILE
  echo $RESULTFILE
  
  RESULTFILE=$WORKDIR/$1/$DATE'_procecures.sql'
  sqldump '--no-create-info --no-data --extended-insert=false --triggers=false --routines' $RESULTFILE
  echo $RESULTFILE
}

function dump_minutely ()
{
  echo "Minutely"
  MINUTES=$(echo "60" | bc)
  dumpAll 'minutely'
  find $WORKDIR/minutely/ -maxdepth 1 -name "*.sql" -mmin +$MINUTES -delete
}

function dump_hourly ()
{
  echo "Hourly"
  MINUTES=$(echo "60*12" | bc)
  dumpAll 'hourly'
  echo find $WORKDIR/minutely/ -maxdepth 1 -name "*.sql" -mmin +$MINUTES -delete
}

function dump_daily ()
{
  echo "Daily"
  MINUTES=$(echo "60*24" | bc)
  dumpAll 'hourly'
  echo find $WORKDIR/minutely/ -maxdepth 1 -name "*.sql" -mmin +$MINUTES -delete
}

function dump_weekly ()
{
  echo "Weekly"
  MINUTES=$(echo "60*24*7*4" | bc)
  dumpAll 'weekly'
  echo find $WORKDIR/minutely/ -maxdepth 1 -name "*.sql" -mmin +$MINUTES -delete
}

function dump_monthly ()
{
  echo "Weekly"
  MINUTES=$(echo "60*24*30*12" | bc)
  dumpAll 'weekly'
  echo find $WORKDIR/minutely/ -maxdepth 1 -name "*.sql" -mmin +$MINUTES -delete
}

echo 'Start '`date +%Y-%m-%d_%H:%M:%S`

case $1 in
  "minutely") dump_minutely;;
  "hourly") dump_hourly;;
  "daily") dump_daily;;
  "weekly") dump_weekly;;
  "monthly") dump_monthly;;
  *) echo "No reasonable options found!";;
esac

echo 'End '`date +%Y-%m-%d_%H:%M:%S`
echo ''
echo `dirname $0`
