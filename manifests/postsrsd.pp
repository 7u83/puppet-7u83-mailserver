#
# postsrsd
#

class mailserver::postsrsd(
	$srs_domain,
	$srs_exclude_domains = [],
)
{

	$xdomains_arg = join($srs_exclude_domains,",")

        case $::osfamily {

                'FreeBSD':{
			Mailserver::Sysrc["postsrsd_domain"] -> Service[$service]
			Mailserver::Sysrc["postsrsd_exclude_domains"] -> Service[$service]

			ensure_resource ("package","portupgrade",{
			})

			$pkg = "postsrsd"
			$service = "postsrsd"

			mailserver::sysrc{"postsrsd_domain":
				ensure => "$srs_domain"
			}
			mailserver::sysrc{"postsrsd_exclude_domains":
				ensure => "$xdomains_arg"
			}
		}
		default: {
			$pkg = "postsrsd"
			$service = "postsrsd"

			
		}


	}	

	package {"$pkg":
		ensure => 'installed',
	}

	file {"/tmp/srs_domain":
		ensure => present,
		content => "$srs_domain $xdomains_arg",
	}

	service {"$service":
		ensure => running,
		require => File["/tmp/srs_domain"],
		subscribe => File["/tmp/srs_domain"],
	}

}
