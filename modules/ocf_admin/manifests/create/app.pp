class ocf_admin::create::app {
  package { 'ocf-create':; }

  service { 'ocf-create':
    require => Package['ocf-create'];
  }

  # these get shoved into URIs, and we can't deal with escaping
  $redis_password = file('/opt/puppet/shares/private/create/redis-password')
  validate_re($redis_password, '^[a-zA-Z0-9]*$', 'Bad Redis password')
  $mysql_password = file('/opt/puppet/shares/private/create/mysql-password')
  validate_re($mysql_password, '^[a-zA-Z0-9]*$', 'Bad MySQL password')

  $broker = "redis+socket://:${redis_password}@/var/run/redis/redis.sock"
  $backend = $broker

  augeas { '/etc/ocf-create/ocf-create.conf':
    lens      => 'Puppet.lns',
    incl      => '/etc/ocf-create/ocf-create.conf',
    changes   =>  [
      "set mysql/uri mysql+pymysql://ocfcreate:${mysql_password}@mysql/ocfcreate",
      "set celery/broker ${broker}",
      "set celery/backend ${backend}",
    ],
    show_diff => false,
    notify    => Service['ocf-create'],
    require   => Package['ocf-create'];
  }

  File {
    require => Package['ocf-create'],
  }

  file {
    # TODO: ideally this file wouldn't be directly readable by staff
    '/etc/ocf-create/ocf-create.conf':
      owner  => create,
      group  => approve,
      mode   => '0440';

    '/etc/ocf-create/create.keytab':
      owner  => create,
      group  => root,
      mode   => '0400',
      source => 'puppet:///private/create.keytab';

    '/etc/ocf-create/create.key':
      owner  => create,
      group  => root,
      mode   => '0400',
      source => 'puppet:///private/create.key';

    '/etc/ocf-create/create.pub':
      owner  => create,
      group  => root,
      mode   => '0444',
      source => 'puppet:///private/create.pub';

    '/etc/sudoers.d/create':
      mode   => '0440',
      source => 'puppet:///modules/ocf_admin/create.sudoers';

    # TODO: is this link used by anything?
    '/opt/acct/sorry':
      ensure => link,
      target => '/opt/share/utils/staff/acct/sorry';
  }
}
