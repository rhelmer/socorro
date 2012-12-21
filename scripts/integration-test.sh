#!/bin/bash

# integration test for Socorro
#
# bring up components, submit test crash, ensure that it shows up in 
# reports tables.
#
# This uses the same setup as http://socorro.readthedocs.org/en/latest/installation.html

# set up environment
make virtualenv
. socorro-virtualenv/bin/activate
export PYTHONPATH=.

# set up database
python socorro/external/postgresql/setupdb_app.py --database_name=breakpad --dropdb
pushd tools/dataload
bash import.sh
popd

# copy default config
cp config/collector.ini-dist config/collector.ini
cp config/processor.ini-dist config/processor.ini
cp config/monitor.ini-dist config/monitor.ini
cp config/middleware.ini-dist config/middleware.ini

# start up collector, processor, monitor and API middleware
for p in collector processor monitor middleware
do
  # ensure no running processes
  fuser -k ${p}.log
  python socorro/${p}/${p}_app.py --admin.conf=./config/${p}.ini > ${p}.log 2>&1 &
  # terminate when this script does
  trap "kill $!" SIGTERM
done

# wait for collector to startup
COUNT=0
while true
do
  grep 'running standalone at 127.0.0.1:8882' collector.log
  if [ $? != 0 ]
  then
    echo "collector not running yet, waiting..."
    if [ $COUNT == 10 ]
    then
      echo "ERROR: timeout"
      exit 1
    fi
  else
    echo "collector running"
    break
  fi
  sleep 1
  COUNT=$((COUNT+1))
done

# submit test crash
python socorro/collector/submitter_app.py -u http://localhost:8882/submit -s testcrash/ > submitter.log 2>&1

CRASHID=`grep 'CrashID' submitter.log | awk -FCrashID=bp- '{print $2}'`
echo "collector received crash ID: $CRASHID"

# wait for monitor to pick up crash
COUNT=0
while true
do
  grep $CRASHID monitor.log
  if [ $? != 0 ]
  then
    echo "monitor hasn't picked up crash yet, waiting..."
    if [ $COUNT == 10 ]
    then
      echo "ERROR: timeout"
      exit 1
    fi
  else
    echo "monitor found crash"
    break
  fi
  sleep 1
  COUNT=$((COUNT+1))
done

# wait for processor to pick up crash
COUNT=0
while true
do
  grep $CRASHID processor.log
  if [ $? != 0 ]
  then
    echo "processor hasn't picked up crash yet, waiting..."
    if [ $COUNT == 10 ]
    then
      echo "ERROR: timeout"
      exit 1
    fi
  else
    echo "processor found crash"
    break
  fi
  sleep 1
  COUNT=$((COUNT+1))
done

# TODO check that mware has raw crash
# TODO run backfill
# TODO check that reports have expected data
