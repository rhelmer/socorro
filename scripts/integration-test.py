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

def run(message, commandline, newcwd=None, background=False):
    logging.info('%s...' % message)
    oldcwd = os.getcwd()
    if newcwd:
        os.chdir(newcwd)
    process = None
    if background:
        process = subprocess.Popen(commandline, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    else:
        subprocess.check_call(commandline)
    if newcwd:
        os.chdir(oldcwd)
    logging.info('done')
    return process

def runpy(message, commandline, newcwd=None, background=False):
    os.environ['PYTHONPATH'] = '.'
    cmd = ['socorro-virtualenv/bin/python'] + commandline
    return run(message, ['socorro-virtualenv/bin/python'] + commandline,
               newcwd, background)

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
    
    for name in ['collector', 'processor', 'monitor', 'middleware']:
        defaultconf = 'config/%s.ini-dist' % name
        conf = 'config/%s.ini' % name
        app = 'socorro/%s/%s_app.py' % (name, name)
        appconf = '--admin.conf=./config/%s.ini' % name
      
        run('copying default %s config' % name, ['cp', defaultconf, conf])
        process = runpy('starting up %s' % name, [app, appconf],
                        background=True)
        while True:
            print os.read(process.stdout.fileno, 1)

        print 'killing {}'.format(name)
        process.kill()

if __name__ == '__main__':
    main()
