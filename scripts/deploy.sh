#!/bin/bash
#
# Socorro deploy script
#

if [ $# != 1 ]
then
  echo "Syntax: deploy.sh <url-to-socorro_tar_gz>"
  exit 1
fi

URL=$1

function error {
  if [ $# != 2 ]
  then
    echo "Syntax: error <exit_code> <message>"
    exit 1
  fi
  EXIT_CODE=$1
  MESSAGE=$2
  if [ $EXIT_CODE != 0 ]
  then
    echo "ERROR: $MESSAGE"
    exit $EXIT_CODE
  fi
}

# current date to the second, used for archiving old builds
DATE=`date +%d-%m-%Y_%H_%M_%S`
error $? "could not set date"

# ensure socorro user exists
id socorro > /dev/null
if [ $? != 0 ]; then
    useradd socorro
    error $? "could not create socorro user"
fi

# ensure base directories exist
mkdir -p /etc/socorro
error $? "could not create /etc/socorro"
mkdir -p /var/log/socorro
error $? "could not create /var/log/socorro"
mkdir -p /data/socorro
error $? "could not create /data/socorro"
chown socorro /var/log/socorro
error $? "could not chown /var/log/socorro"
mkdir -p /home/socorro/primaryCrashStore \
    /home/socorro/fallback \
    /home/socorro/persistent
error $? "could not make socorro crash storage directories"
chown apache:socorro /home/socorro/primaryCrashStore /home/socorro/fallback
error $? "could not chown apache on crash storage directories"
chmod 2775 /home/socorro/primaryCrashStore /home/socorro/fallback
error $? "could not chmod crash storage directories"

# download latest successful Jenkins build
OLD_CSUM=""
if [ -f socorro.tar.gz ]
then
  OLD_CSUM=`md5sum socorro.tar.gz | awk '{print $1}'`
  error $? "could not get old checksum"
fi
echo "Downloading socorro.tar.gz"
wget -q -O socorro-new.tar.gz -N $URL
error $? "wget reported failure"

NEW_CSUM=`md5sum socorro-new.tar.gz | awk '{print $1}'`
error $? "could not get new checksum"

if [ "$OLD_CSUM" == "$NEW_CSUM" ]
then
  echo "No changes from previous build, aborting"
  echo "(remove socorro.tar.gz and re-run to proceed anyway)"
  exit 0
fi

# untar new build into tmp area
echo "Unpacking new build"
TMP=`mktemp -d /tmp/socorro-install-$$-XXX`
error $? "mktemp reported failure"
tar -C ${TMP} -zxf socorro-new.tar.gz
error $? "could not untar new Socorro build"

# backup old build
echo "Backing up old build to /data/socorro.${DATE}"
mv /data/socorro /data/socorro.${DATE}
error $? "could not backup old Socorro build"

# install new build
echo "Installing new build to /data/socorro"
mv ${TMP}/socorro/ /data/
error $? "could not install new Socorro build"

# move new socorro.tar.gz over old
mv socorro-new.tar.gz socorro.tar.gz

# deploy system files
cp /data/socorro/application/scripts/crons/socorrorc /etc/socorro/
error $? "could not copy socorrorc"

if [ ! -f /etc/httpd/conf.d/socorro ]; then
    cp /data/socorro/application/config/apache.conf-dist \
        /etc/httpd/conf.d/socorro
    error $? "could not copy socorro apache config"
fi
if [ ! -f /etc/cron.d/socorro ]; then
    # FIXME not landed yet
    #cp /data/socorro/application/config/crontab-dist \
    #    /etc/cron.d/socorro
    #error $? "could not copy socorro crontab"
    echo "*/5 * * * * socorro /data/socorro/application/scripts/crons/crontabber.sh" > /etc/cron.d/socorro
fi
cp /data/socorro/application/config/*.ini-dist /etc/socorro
error $? "could not copy dist files to /etc/socorro"
pushd /etc/socorro
error $? "could not pushd /etc/socorro"
for file in *.ini-dist; do
    if [ ! -f `basename $file -dist` ]; then
        cp $file `basename $file -dist`
        error $? "could not copy ${file}-dist to $file"
    fi
done
popd

# copy system files into install, to catch any overrides
cp /etc/socorro/*.ini /data/socorro/application/config/
error $? "could not copy /etc/socorro/*.ini into install"
cp /etc/socorro/local.py /data/socorro/webapp-django/crashstats/settings/
error $? "could not copy /etc/socorro/local.py into install"

cp /data/socorro/application/scripts/init.d/socorro-processor /etc/init.d/
error $? "could not copy socorro-processor init script"
chkconfig --add socorro-processor
error $? "could not add socorro-processor init script"
chkconfig socorro-processor on
error $? "could not enable socorro-processor init script"
service socorro-processor restart
error $? "could not start socorro-processor"

# create DB if it does not exist
psql -U postgres -h localhost -l | grep breakpad > /dev/null
if [ $? != 0 ]; then
    echo "Creating new DB, may take a few minutes"
    pushd /data/socorro/application > /dev/null
    error $? "Could not pushd /data/socorro"
    export PYTHONPATH=.
    /data/socorro/socorro-virtualenv/bin/python \
        ./socorro/external/postgresql/setupdb_app.py \
        --database_name=breakpad --fakedata \
        --database_superusername=postgres \
        &> /var/log/socorro/setupdb.log
    error $? "Could not create new fakedata DB, see \
        /var/log/socorro/setupdb.log"
    popd > /dev/null
    error $? "Could not popd"
else
    echo "Running database migrations with alembic"
    pushd /data/socorro/application > /dev/null
    error $? "Could not pushd /data/socorro"
    export PYTHONPATH=.
    ../socorro-virtualenv/bin/python ../socorro-virtualenv/bin/alembic \
        -c config/alembic.ini upgrade head > /dev/null
    error $? "Could not run migraions with alembic"
    popd > /dev/null
    error $? "Could not popd"
fi

if [ -f /etc/init.d/socorro-crashmover ]
then
  /sbin/service socorro-crashmover restart
  error $? "could not start socorro-crashmover"
fi
if [ -f /etc/init.d/socorro-processor ]
then
  /sbin/service socorro-processor restart
  error $? "could not start socorro-processor"
fi
if [ -f /etc/init.d/httpd ]
then
  /sbin/service httpd restart
  error $? "could not start httpd"
fi

echo "Running Django syncdb"
/data/socorro/webapp-django/virtualenv/bin/python \
    /data/socorro/webapp-django/manage.py syncdb --noinput > /dev/null
which lessc > /dev/null
if [ $? != 0 ]; then
    echo "Installing lessc with npm"
    npm install -g less > /dev/null
    error $? "could not npm install -g less"
fi

echo "Socorro build installed successfully!"
echo "Downloaded from ${URL}"
echo "Checksum: ${NEW_CSUM}"
echo "Backed up original to /data/socorro.${DATE}"
