import codecs
import glob
import os
from setuptools import setup, find_packages


# Prevent spurious errors during `python setup.py test`, a la
# http://www.eby-sarna.com/pipermail/peak/2010-May/003357.html:
try:
    import multiprocessing
except ImportError:
    pass


setup(
    name='socorro',
    version='master',
    description=('Socorro is a server to accept and process Breakpad'
                 ' crash reports.'),
    author='Mozilla',
    author_email='socorro-dev@mozilla.com',
    license='MPL',
    url='https://github.com/mozilla/socorro',
    classifiers=[
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'License :: OSI Approved :: MPL License',
        'Programming Language :: Python :: 2.6',
        'Programming Language :: Python :: 2.7',
        'Topic :: Internet :: WWW/HTTP :: WSGI :: Application',
        ],
    keywords=['socorro', 'breakpad', 'crash', 'reporting', 'minidump',
              'stacktrace'],
    packages=find_packages(),
    install_requires=['configman==1.2.8', 'configobj==4.7.2',
        'isodate==0.4.7', 'lxml==2.3.4', 'pika==0.9.8',
        'elasticsearch==1.2', 'elasticsearch-dsl==0.0.2',
        'pyelasticsearch==0.6.1', 'urllib3==1.9.1', 'elasticutils==0.7',
        'raven==3.4.1', 'requests==1.2.3', 'simplejson==2.5.0', 'six==1.7.3',
        'statsd==2.1.2', 'suds==0.4', 'web.py==0.36',
        'wsgiref==0.1.2', 'ujson==1.33', 'python-dateutil==2.1',
        'ordereddict==1.1', 'crontabber==0.15', 'boto==2.28.0',
        'pyquery==1.2.6', 'python-memcached==1.48', 'BeautifulSoup==3.2.1',
        'path.py==5.1', 'sasl==0.1.3', 'pyOpenSSL==0.14',
        'ndg-httpsclient==0.3.2', 'pyasn1==0.1.7', 'poster==0.8.1',
        'psycopg2==2.4.5', 'pyhs2==0.6.0'],
    entry_points={
        'console_scripts': [
                'socorro = socorro.app.socorro_app:SocorroWelcomeApp.run'
            ],
        },
    test_suite='nose.collector',
    zip_safe=False,
    data_files=[
        ('socorro/external/postgresql/raw_sql/procs',
            glob.glob('socorro/external/postgresql/raw_sql/procs/*.sql')),
        ('socorro/external/postgresql/raw_sql/views',
            glob.glob('socorro/external/postgresql/raw_sql/views/*.sql')),
        ('socorro/external/postgresql/raw_sql/types',
            glob.glob('socorro/external/postgresql/raw_sql/types/*.sql')),
    ],
),
