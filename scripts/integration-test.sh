#!/bin/bash

# integration test for Socorro
#
# bring up components, submit test crash, ensure that it shows up in 
# reports tables.
#
# This uses the same setup as http://socorro.readthedocs.org/en/latest/installation.html

echo -n "INFO: setting up environment..."
make virtualenv > setup.log 2>&1
. socorro-virtualenv/bin/activate >> setup.log 2>&1
export PYTHONPATH=.
echo " Done."

echo -n "INFO: setting up database..."
python socorro/external/postgresql/setupdb_app.py --database_name=breakpad --dropdb --force > setupdb.log 2>&1
pushd tools/dataload >> setupdb.log 2>&1
bash import.sh >> setupdb.log 2>&1
popd >> setupdb.log 2>&1
python socorro/cron/crontabber.py  -j socorro.cron.jobs.weekly_reports_partitions.WeeklyReportsPartitionsCronApp -f >> setupdb.log 2>&1
echo " Done."

echo -n "INFO: copying default config..."
cp config/collector.ini-dist config/collector.ini
cp config/processor.ini-dist config/processor.ini
cp config/monitor.ini-dist config/monitor.ini
cp config/middleware.ini-dist config/middleware.ini
echo " Done."

echo -n "INFO: starting up collector, processor, monitor and middleware..."
for p in collector processor monitor middleware
do
  # ensure no running processes
  fuser -k ${p}.log > /dev/null 2>&1
  python socorro/${p}/${p}_app.py --admin.conf=./config/${p}.ini > ${p}.log 2>&1 &
  # terminate when this script does
  sleep 5
done
echo " Done."

function retry() {
  name=$1
  search=$2

  count=0
  while true
  do
    grep "$search" ${name}.log > /dev/null
    if [ $? != 0 ]
    then
      echo "INFO: waiting for $name..."
      if [ $count == 10 ]
      then
        echo "ERROR: $name timeout"
        exit 1
      fi
    else
      echo "INFO: $name test passed"
      break
    fi
    sleep 5
    count=$((count+1))
  done
  }

# wait for collector to startup
retry 'collector' 'running standalone at 127.0.0.1:8882'

echo -n 'INFO: submitting test crash...'
# submit test crash
python socorro/collector/submitter_app.py -u http://localhost:8882/submit -s testcrash/ > submitter.log 2>&1
echo " Done."

CRASHID=`grep 'CrashID' submitter.log | awk -FCrashID=bp- '{print $2}'`
echo "INFO: collector received crash ID: $CRASHID"

# make sure crashes are picked up
retry 'monitor' "$CRASHID"
retry 'processor' "$CRASHID"

# TODO check that mware has raw crash
# TODO run backfill
# TODO check that reports have expected data
