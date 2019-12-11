#
class mailserver::install_spawn_fcgi
(
	$app,
	$app_args,
	$bindsocket,
	$bindsocket_mode,
	$bindaddr,
	$bindport,
	$username,
	$groupname,
)
{
        case $::osfamily {
                'FreeBSD':{
			package {"spawn-fcgi":
				ensure => installed
			}

			mailserver::sysrc{"spawn_fcgi_app":
				ensure => "$app"
			}
			mailserver::sysrc{"spawn_fcgi_app_args":
				ensure => "$app_args"
			}
			mailserver::sysrc{"spawn_fcgi_bindsocket":
				ensure => "$bindsocket"
			}
			mailserver::sysrc{"spawn_fcgi_bindsocket_mode":
				ensure => "$bindsocket_mode"
			}

			mailserver::sysrc{"spawn_fcgi_username":
				ensure => "$username"
			}

			mailserver::sysrc{"spawn_fcgi_groupname":
				ensure => "$username"
			}

			mailserver::sysrc{"spawn_fcgi_bindaddr":
				ensure => "$bindaddr"
			}
			mailserver::sysrc{"spawn_fcgi_bindport":
				ensure => "$bindport"
			}
			
		}
		default: {
 		}	
	}

}
