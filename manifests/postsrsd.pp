#
# postsrsd
#

class mailserver::postsrsd(
	$srs_domain
)
{
        case $::osfamily {

                'FreeBSD':{
			ensure_resource ("package","portupgrade",{
			})

			$pkg = "postsrsd"
			$service = "postsrsd"

			package {"$pkg":
				ensure => 'installed',
			}

			mailserver::sysrc{"postsrsd_domain":
				ensure => "$srs_domain"
			}

		}
	}	

	file {"/tmp/srs_domain":
		ensure => present,
		content => "$srs_domain",
	}

	Mailserver::Sysrc["postsrsd_domain"] -> Service[$service]

	service {"$service":
		ensure => running,
		require => File["/tmp/srs_domain"],
		subscribe => File["/tmp/srs_domain"],
	}

}
