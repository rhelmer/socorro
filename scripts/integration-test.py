#!/usr/bin/env python
#
# integration test for Socorro
#
# bring up components, submit test crash, ensure that it shows up in 
# reports tables.
#
# This uses the same setup as:
# http://socorro.readthedocs.org/en/latest/installation.html

import logging
import os
import subprocess

logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.DEBUG)

def run(message, commandline, newcwd=None):
    logging.info('%s...' % message)
    oldcwd = os.getcwd()
    if newcwd:
        os.chdir(newcwd)
    logging.debug(os.getcwd())
    subprocess.check_call(commandline)
    if newcwd:
        os.chdir(oldcwd)
    logging.info('done')

def runpy(message, commandline):
    os.environ['PYTHONPATH'] = '.'
    cmd = ['socorro-virtualenv/bin/python'] + commandline
    logging.debug(cmd)
    run(message, ['socorro-virtualenv/bin/python'] + commandline)

def main():
    run('setting up environment', ['make', 'virtualenv'])
    runpy('setting up database',
          ['socorro/external/postgresql/setupdb_app.py',
           '--database_name=breakpad', '--dropdb', '--force'])

    run('importing data', ['bash', 'import.sh'], 'tools/dataload')

    run('copying default createpartitions config',
        ['cp', 'scripts/config/createpartitionsconfig.py.dist',
         'scripts/config/createpartitionsconfig.py'])
    runpy('create reports table partitions', ['scripts/createPartitions.py'])
    
    for process in ['collector', 'processor', 'monitor', 'middleware']:
        defaultconf = 'config/%s.ini-dist' % process
        conf = 'config/%s.ini' % process
        app = 'socorro/%s/%s_app.py' % (process, process)
        appconf = '--admin.conf=./config/%s.ini' % process
      
        run('copying default %s config' % process, ['cp', defaultconf, conf])
        runpy('starting up %s' % process, [app, appconf])

if __name__ == '__main__':
    main()
