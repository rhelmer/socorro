# Set up basic Socorro requirements.
class webapp::socorro {

  service {
    'iptables':
      ensure => stopped,
      enable => false;

    'httpd':
      ensure  => running,
      enable  => true,
      require => Package['httpd'];

    'memcached':
      ensure  => running,
      enable  => true,
      require => Package['memcached'];

    'rabbitmq-server':
      ensure  => running,
      enable  => true,
      require => Package['rabbitmq-server'];

    'postgresql-9.3':
      ensure  => running,
      enable  => true,
      require => [
          Package['postgresql93-server'],
          Exec['postgres-initdb'],
        ];

    'elasticsearch':
      ensure  => running,
      enable  => true,
      require => Package['elasticsearch'];
  }

  exec {
    'postgres-initdb':
      command => '/sbin/service postgresql-9.3 initdb'
  }

  yumrepo {
    'PGDG':
      baseurl  => 'http://yum.postgresql.org/9.3/redhat/rhel-$releasever-$basearch',
      descr    => 'PGDG',
      enabled  => 1,
      gpgcheck => 0;

    'EPEL':
      baseurl  => 'http://ftp.osuosl.org/pub/fedora-epel/$releasever/$basearch',
      descr    => 'EPEL',
      enabled  => 1,
      gpgcheck => 0;

    'devtools':
      baseurl  => 'http://people.centos.org/tru/devtools-1.1/$releasever/$basearch/RPMS',
      enabled  => 1,
      gpgcheck => 0;

    'elasticsearch':
      baseurl  => 'http://packages.elasticsearch.org/elasticsearch/0.90/centos',
      enabled  => 1,
      gpgcheck => 0;
  }

  package {
    [
      'subversion',
      'make',
      'rsync',
      'time',
      'gcc-c++',
      'python-devel',
      'git',
      'libxml2-devel',
      'libxslt-devel',
      'openldap-devel',
      'java-1.7.0-openjdk',
      'yum-plugin-fastestmirror',
      'httpd',
      'mod_wsgi',
      'memcached',
      'daemonize',
    ]:
    ensure => latest
  }

  package {
    [
      'postgresql93-server',
      'postgresql93-plperl',
      'postgresql93-contrib',
      'postgresql93-devel',
    ]:
    ensure  => latest,
    require => [ Yumrepo['PGDG'], Package['yum-plugin-fastestmirror']]
  }

  package {
    [
      'python-virtualenv',
      'supervisor',
      'rabbitmq-server',
      'python-pip',
      'npm',
    ]:
    ensure  => latest,
    require => [ Yumrepo['EPEL'], Package['yum-plugin-fastestmirror']]
  }

  package {
    'elasticsearch':
      ensure  => latest,
      require => [ Yumrepo['elasticsearch'], Package['java-1.7.0-openjdk'] ]
  }

  package {
    'devtoolset-1.1-gcc-c++':
      ensure  => latest,
      require => [ Yumrepo['devtools'], Package['yum-plugin-fastestmirror']]
  }

  file {
    'pg_hba.conf':
      path => '/var/lib/pgsql/9.3/data/pg_hba.conf',
      source => '/vagrant/puppet/files/var_lib_pgsql_9.3_data/pg_hba.conf',
      owner => 'postgres',
      group => 'postgres',
      ensure => file,
      notify => Service['postgresql-9.3'];

    'alembic.ini':
      path => '/etc/socorro/alembic.ini',
      source => '/vagrant/puppet/files/config/alembic.ini',
      ensure => file;

    'collector.ini':
      path => '/etc/socorro/collector.ini',
      source => '/vagrant/puppet/files/config/collector.ini',
      ensure => file;

    'middleware.ini':
      path => '/etc/socorro/middleware.ini',
      source => '/vagrant/puppet/files/config/middleware.ini',
      ensure => file;

    'socorro_apache.conf':
      path => '/etc/httpd/conf.d/socorro.conf',
      source => '/vagrant/puppet/files/etc_httpd_conf.d/socorro.conf',
      owner => 'apache',
      ensure => file,
      notify => Service['httpd'];

    'socorro_crontab':
      path => '/etc/cron.d/socorro',
      source => '/vagrant/puppet/files/etc_cron.d/socorro',
      owner => 'root',
      ensure => file;

    'socorro_django_local.py':
      path => '/etc/socorro/local.py',
      source => '/vagrant/puppet/files/config/local.py',
      ensure => file;
  }

}
