# sendmail

class mailserver::sendmail::params
(
  $server_cert = "CERT_DIR/host.cert",
  $server_key = "CERT_DIR/host.key",
  $cacert = "CERT_DIR/cacert.pem",
  $cacert_path = "CERT_DIR",
  $system = true,
  
){
  case $::osfamily {
    'FreeBSD':{
  		$service = 'sendmail'
      $etc_mail = '/etc/mail'
  		$mail_uid = 'mailnull'
  		$mail_gid = 'mailnull'
  		$ostype = 'freebsd6'
  		$mta_domain = 'generic'
  		$submit_domain = 'generic'
  		$pid_dir = "/var/run"
  	}
  	'Debian':{
  		$service = 'sendmail'
  		$etc_mail = '/etc/mail'
  		$ostype = 'debian'
  		$mail_uid = 'smmta'
  		$mail_gid = 'smmta'
  		$mta_domain = 'debian-mta'
  		$submit_domain = 'debian-msp'
  		$pid_dir = "/var/run"
	  }
  }

  $cert_dir = "$etc_mail/certs"

	$local_host_names = "$etc_mail/local-host-names"
	$sendmail_mc = "$etc_mail/sendmail.mc"
	$sendmail_cf = "$etc_mail/sendmail.cf"
	$submit_mc = "$etc_mail/submit.mc"
	$submit_cf = "$etc_mail/submit.cf"
	$alias_files = [
		"$etc_mail/aliases"
	]

  case $::osfamily {
    'FreeBSD':{
      file {"/etc/make.conf":
        ensure => file,
			}
			
			file_line {"bsdmakeconf_sendmail":
				ensure => present,
				path => "/etc/make.conf",	
				line => "SENDMAIL_MC=${sendmail_mc}\t#created by puppet",
				match => "^SENDMAIL_MC.*=",
				require => File["/etc/make.conf"]
			}
			
			file_line {"bsdmakeconf_sendmail_submit":
				ensure => present,
				path => "/etc/make.conf",	
				line => "SENDMAIL_SUBMIT_MC=/etc/mail/submit.mc\t#created by puppet",
				match => "^SENDMAIL_SUBMIT_MC.*=",
				require => File["/etc/make.conf"]
			}
		}
		'Debian':{
		}
	}


}

class mailserver::sendmail(

	$myhostname = $trusted['hostname'],
	$myorigin = $myhostname,
	$mydestination = [$myhostname],

	$ldap = false,
	$sasl = false,
	$input_milters=[],

	$groups = [],

	$pid_dir = $mailserver::sendmail::params::pid_dir,

	$system = $mailserver::sendmail::params::system,
	$alias_files = $mailserver::sendmail::params::alias_files,
	$additional_alias_files = [],

  
)
inherits mailserver::sendmail::params
{
	class {"mailserver::sendmail::install":
		ldap => $ldap,
		sasl => $sasl
	}

	$makemap_cmd = $mailserver::sendmail::install::makemap_cmd
  $makealiases_cmd = $mailserver::sendmail::install::makealiases_cmd

	if $system {
		mailserver::sendmail::instance{'default':
			require => Anchor["sendmail_installed"],
		}
	}

#	service{ $service:
#		ensure => running,
#		require => [
#			Concat[$sendmail_mc],
#			File[$submit_mc],
#			Anchor["sendmail_installed"],
#		],
#		subscribe => Anchor["sendmail_installed"],
#	}

	$bindir_config = $::mailserver::sendmail::install::bindir_config

	file {$submit_mc:
		ensure => file,
		content => template("mailserver/sendmail/submit.mc.erb"),
	} ->
	exec {"make submit.cf":
		command => "${mailserver::sendmail::install::m4_cmd} $submit_mc > $submit_cf",
		refreshonly => true,
		subscribe => File[$submit_mc],
#		notify => Service[$service],
	}

	file{$local_host_names:
		ensure => file,
		content => template("mailserver/sendmail/local-host-names.erb"),
	}
	user {"$mail_uid":
		ensure => present,
		groups => $groups,
		require => Anchor["sendmail_installed"]
	}

}
	

class mailserver::sendmail::install(
	$ldap = false,
	$sasl = false,	
	$ensure = 'latest',
)
{
	$use_bsd_ports = $ldap 
	$use_bsd_package = $sasl
	$use_bsd_local = !($ldap or $sasl)
 
	case $::osfamily {
    'FreeBSD':{
		  ensure_resource("file","/usr/local/etc/mail",{
				ensure => directory
			})


			$package = 'sendmail'
#			file {"/usr/local/etc/mail":
#				ensure => directory
#			}

			if $use_bsd_local {

				$makemap_cmd = "/usr/sbin/makemapp"
				$makealiases_cmd = "/usr/bin/newaliases"

				$m4_cmd = '/usr/bin/m4 -D_CF_DIR_=/usr/share/sendmail/cf/   /usr/share/sendmail/cf/m4/cf.m4'
				# use local
				package {"sendmail":
					ensure => absent,
					notify => Anchor["sendmail_installed"],
				} ->
				file {"sendmail_mailer_conf":
					path => "/usr/local/etc/mail/mailer.conf",
					ensure => absent,
				}->
				file_line {"bsdmakeconf_sendmail_cf":
					ensure => absent,
					path => "/etc/make.conf",	
					line => "SENDMAIL_CF_DIR=/usr/local/share/sendmail/cf\t#created by puppet",
					match => "^SENDMAIL_CF_DIR.*=",
					require => File["/etc/make.conf"]
				}->
				anchor {"sendmail_pkg_installed":}
			}
			else {
				$makemap_cmd = "/usr/local/sbin/makemapp"
				$makealiases_cmd = "/usr/local/bin/newaliases"

				$bindir_config = "define(`confEBINDIR', `/usr/local/libexec')dnl
define(`UUCP_MAILER_PATH', `/usr/local/bin/uux')dnl"
				$m4_cmd = '/usr/bin/m4 -D_CF_DIR_=/usr/local/share/sendmail/cf/   /usr/local/share/sendmail/cf/m4/cf.m4'
				if $use_bsd_ports {
					$package_settings  = {
						'LDAP' => $ldap,
						'SASL' => $sasl,
					}
					$package_provider = 'portsng'
				}
				else {
					$package_settings = undef
					$package_provider = undef
				}

				package {"sendmail":
					ensure => $ensure,
					provider => $package_provider,
					notify => Anchor["sendmail_installed"],
				} ->
				file {"sendmail_mailer_conf":
					path => "/usr/local/etc/mail/mailer.conf",
					ensure => file,
					content => template("mailserver/sendmail/mailer.conf.erb"),
					require => File["/usr/local/etc/mail"],
				}->
				file_line {"bsdmakeconf_sendmail_cf":
					ensure => present,
					path => "/etc/make.conf",	
					line => "SENDMAIL_CF_DIR=/usr/local/share/sendmail/cf\t#created by puppet",
					match => "^SENDMAIL_CF_DIR.*=",
					require => File["/etc/make.conf"]
				}->
				anchor {"sendmail_pkg_installed":}
			}

			anchor {"sendmail_installed":
				require => Anchor["sendmail_pkg_installed"],
			}

	
		}
		'Debian':{
			$m4_cmd = '/usr/bin/m4 -D_CF_DIR_=/usr/share/sendmail/cf/   /usr/share/sendmail/cf/m4/cf.m4'
			package {"sendmail":
				ensure => present,
				notify => Anchor["sendmail_installed"],
			} ->
			anchor {"sendmail_pkg_installed":
			} 

			anchor {"sendmail_installed":
				require => Anchor["sendmail_pkg_installed"],
			}
		}
	}
}






define mailserver::sendmail::instance(
	$myhostname = $mailserver::sendmail::myhostname,
	$input_milters = [],
	$alias_files = $mailserver::sendmail::alias_files,
	$additional_alias_files = $mailserver::sendmail::additional_alias_files,

	$cert_dir  = "${mailserver::sendmail::cert_dir}",
	$server_cert  = "${mailserver::sendmail::server_cert}",
	$server_key  = "${mailserver::sendmail::server_key}",
	$cacert  = "${mailserver::sendmail::cacert}",
	$cacert_path  = "${mailserver::sendmail::cacert_path}",

){
	if $title != 'default' {
		$instance_name = "-$title"
	}

	$_alias_files = concat( $alias_files, $additional_alias_files,[])

	$service = "sendmail${instance_name}"
	$pid_file = "${mailserver::sendmail::pid_dir}/sendmail${instance_name}.pid"
	$cfg_file = "${mailserver::sendmail::etc_mail}/sendmail${instance_name}.cf"
	$sendmail_mc = "${mailserver::sendmail::etc_mail}/sendmail${instance_name}.mc"
	$sendmail_cf = "${mailserver::sendmail::etc_mail}/sendmail${instance_name}.cf"
	$ostype = "$mailserver::sendmail::ostype"
	$mta_domain = "$mailserver::sendmail::mta_domain"
	$bindir_config = "${mailserver::sendmail::install::bindir_config}"
	$local_host_names = "${mailserver::sendmail::local_host_names}"

	if $title != 'default' {
		$status_cmd = "/bin/test -f $pid_file && ps -Ao pid | grep `head -1 $pid_file`"
		$stop_cmd = " ( /bin/test -f $pid_file && kill `head -1 $pid_file` ) || /usr/bin/true"
		$restart_cmd = "/bin/kill -HUP `head -1 $pid_file`"
		$start_cmd = "/usr/sbin/sendmail -C $cfg_file -bd"
	}


	service {$service:
		ensure => running,
		start => $start_cmd,
		stop => $stop_cmd,
		status => $status_cmd,
		restart => $restart_cmd,
		require => [
			Exec["make${sendmail_cf}"],
		],
		subscribe => Anchor["sendmail_installed"],
	}	

	concat { "$sendmail_mc": 
		ensure => present,
	} ->
	exec {"make${sendmail_cf}":
		command => "${mailserver::sendmail::install::m4_cmd} $sendmail_mc > $sendmail_cf",
		refreshonly => true,
		subscribe => Concat[$sendmail_mc],
		notify => Service[$service],
	}

	concat::fragment { "${sendmail_cf}-head":
		target => "$sendmail_mc",
		order => '00',
		content => template('mailserver/sendmail/sendmail.mc-head.erb'),
	} 

	concat::fragment { "${sendmail_cf} foot":
		target => "$sendmail_mc",
		order => '99',
		content => template('mailserver/sendmail/sendmail.mc-foot.erb'),
	} 

}


define mailserver::sendmail::service (
	$input_milters = [],
	$port = $title,
	$etrn = true,
	$require_auth = false,

	$instance ,
)
{
	if $instance != 'default' {
		$instance_name = "-${instance}"
	}

	$sendmail_mc = "${mailserver::sendmail::etc_mail}/sendmail${instance_name}.mc"
	$sendmail_cf = "${mailserver::sendmail::etc_mail}/sendmail${instance_name}.cf"

	concat::fragment  { "${sendmail_mc}-$title":
		target => "$sendmail_mc",
		content => template("mailserver/sendmail/sendmail.mc-service.erb");
	}	
}




define mailserver::sendmail::mta(
	$myhostname = $mailserver::sendmail::myhostname,
	$port = $title,
)
{
	if ! $mailserver::sendmail::system {
		mailserver::sendmail::instance{"$title":
			system => false,
			input_milters => $input_milters,
			require => Anchor["sendmail_installed"],
		}
		mailserver::sendmail::service{ $title:
			port => $port,
			instance => "$title",		
		}
	}
	else {
		mailserver::sendmail::service{ $title:
			port => $port,
			instance => "system",		
		}
	}
}


class mailserver::sendmail::submission(
	$input_milters = [],
)
inherits mailserver::sendmail
{
	if $mailserver::sendmail::system {
		$instance = 'default'
	}
	else {
		$instance = 'submission'
		mailserver::sendmail::instance{$instance:
		}
	}

	mailserver::sendmail::service{ "submission":
		port => 'submission',
		instance => $instance,
		require_auth => true,
		input_milters => $input_milters,
	}
}

class mailserver::sendmail::mx(
	$input_milters = [],
  $server_cert = undef,
  $server_key = undef,
  $cacert_path = undef,
)
inherits mailserver::sendmail
{
	if $mailserver::sendmail::system {
		$instance = 'default'
	}
	else {
		$instance = 'smtp'
		mailserver::sendmail::instance{$instance:
		}
	}

	mailserver::sendmail::service{ "smtp":
		port => 'smtp',
		instance => $instance,
		require_auth => false,
		input_milters => $input_milters,
	}
}
