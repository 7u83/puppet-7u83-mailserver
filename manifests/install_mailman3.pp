#
#
#
#

class mailserver::install_mailman3
(
	$core = true,
	$remove_dkim, 
)
inherits mailserver::params

{

        case $::osfamily {
                'FreeBSD':{
			

			$packages = ["python2","python3","py36-sqlite3","security/ca_root_nss"] #,"devel/py-pip"]
			$pip3 = "/usr/local/bin/pip3"
			$python3 = "/usr/local/bin/python3"

			ensure_resource(
				"package", $packages,
				{
					ensure => "installed"
				}
			)

			exec { "installpip2":
				command => "/usr/local/bin/python2 -m ensurepip --upgrade",
				creates => "/usr/local/bin/pip",
				require => Package[$packages],
			}
			
			exec { "installpip3":
				command => "/usr/local/bin/python3 -m ensurepip",
				creates => "/usr/local/bin/pip3",
				require => Package[$packages]
			}
			
			$mailman_packages = ["mailman","mailman-hyperkitty"]
			package {$mailman_packages:
				provider => "pip3",
				ensure => installed,
				require => [Exec["installpip3"]],
			}
			$mailman_webpackages = ["hyperkitty","postorius"]
			package {$mailman_webpackages:
				provider => "pip",
				ensure => installed,
				require => [Exec["installpip2"]],
				
			}

		}
		default: {
		}
	}

	$_remove_dkim = $remove_dkim  ? {
		true => "yes",
		false => "no",
	}

	$mailman_extdir = "$mailman_etcdir/mailman.d"
	$mailman_dirs = [
			$mailman_dbdir,
			$mailman_piddir, 
			$mailman_vardir, 
			$mailman_extdir,
			$mailman_spooldir,
			$mailman_logdir,
	]
	$mailman_pidfile = "$mailman_piddir/master.pid"

	file {$mailman_dirs:
		ensure => directory,
		owner => $mailman_user,
		group => $mailman_group,
		require => User[$mailman_user],
	}

	group {"$mailman_group":
		ensure => present
	}

	user {"$mailman_user":
		ensure => present,
		gid => $mailman_group,
		home => $mailman_vardir,
		require => [ Group[$mailman_group] ],
		shell => $mailman_shell,
		
	}

	file {"$mailman_cfg":
		ensure => file,
		owner => $mailman_user,
		group => $mailman_group,
		require => User[$mailman_user],
		content => template("mailserver/mailman.cfg.erb"),
	}



#	exec {"install mailman 3 from pip":
#		command => "$python3 -m ensurepip && $pip3 install mailman",
#		require => Package[$packages],
#	}


	exec {"$sucmd $mailman_user -c '$mailman_bindir/mailman aliases'":
		creates => "$mailman_vardir/data",
		require => File[$mailman_cfg],
	}
 
}



class mailserver::mailman_service (
) inherits mailserver::params

 {
	service {"mailman_service":
		provider => "base",
		ensure => "running",
		start => "$sucmd  $mailman_user -c '$mailman_bindir/mailman start'",
		stop => "$sucmd $mailman_user -c '$mailman_bindir/mailman stop'",
		status => "$sucmd $mailman_user -c '$mailman_bindir/mailman status > /tmp/mailman.status ; ! grep -q not /tmp/mailman.status'",
		restart => "$sucmd $mailman_user -c '$mailman_bindir/mailman restart'",
		hasstatus => true,
		hasrestart => true,
		subscribe => Class["mailserver::install_mailman3"],
		require => Class["mailserver::install_mailman3"],
#		pattern => "master",
		
	}

}


