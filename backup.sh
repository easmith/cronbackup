#!/bin/bash

# @author: Eugene Smith http://easmith.github.io/
# 
# Usage:
# ./backup.sh cron database

DATABASE=$2
ENCODING="utf8"
DATE=`date +%Y%m%d%H%M%S`
WORKDIR=$(realpath `dirname $0`)

function sqldump ()
{
  mysqldump --defaults-file=$WORKDIR/mysql.conf --single-transaction --dump-date=false --set-charset --default-character-set=$ENCODING $1 --result-file=$2 $DATABASE
}

function dumpAndClear ()
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

  find $WORKDIR/$1/ -maxdepth 1 -name "*.sql" -mmin +$2 -delete
}

function showcron ()
{
  DATABASE=$1
  echo "Cron jobs for database '$DATABASE':"
  SCRIPT_NAME=`basename $0`
  CRON_MINUTELY="15/15 * * * * /PATHTO/$SCRIPT_NAME minutely $DATABASE >> /PATHTO/minutely.log 2>&1"
  CRON_HOURLY="0 * * * * /PATHTO/$SCRIPT_NAME hourly $DATABASE >> /PATHTO/hourly.log 2>&1"
  CRON_DAILY="7 4 * * * /PATHTO/$SCRIPT_NAME daily $DATABASE >> /PATHTO/daily.log 2>&1"
  CRON_WEEKLY="22 4 * * 0 /PATHTO/$SCRIPT_NAME weekly $DATABASE >> /PATHTO/weekly.log 2>&1"
  CRON_MONTHLY="37 4 1 * * /PATHTO/$SCRIPT_NAME monthly $DATABASE>> /PATHTO/monthly.log 2>&1"
  CRON_TOTAL="\n$CRON_MINUTELY\n$CRON_HOURLY\n$CRON_DAILY\n$CRON_WEEKLY\n$CRON_MONTHLY\n\n"
  printf "${CRON_TOTAL//"/PATHTO"/$WORKDIR}"
}

echo 'Start '`date +%Y-%m-%d_%H:%M:%S`
case $1 in
  "minutely") dumpAndClear $1 $(echo "60" | bc) ;;
  "hourly") dumpAndClear $1 $(echo "60*12" | bc) ;;
  "daily") dumpAndClear $1 $(echo "60*24" | bc) ;;
  "weekly") dumpAndClear $1 $(echo "60*24*7*4" | bc) ;;
  "monthly") dumpAndClear $1 $(echo "60*24*30*12" | bc) ;;
  "cron") showcron $2;;
  *) echo "No reasonable options found!";;
esac
echo 'End '`date +%Y-%m-%d_%H:%M:%S`
