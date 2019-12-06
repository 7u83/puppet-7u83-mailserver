#
# inetd.pp
#


class mailserver::inetd::params {
        case $::osfamily {
                'FreeBSD':{
			$service = "inetd"
			$conf = "/etc/inetd.conf"
		}
	}

}

class mailserver::inetd(
	$ensure = 'running',
	$enable = true
)
inherits mailserver::inetd::params
{
	service {$service:
		ensure => $ensure,
		enable => $enable,
	}
}

define mailserver::inetd::service(
	$service_name = $title,
	$socket_type = 'stream',
	$protocol = 'tcp',
	$wait = false,
	$user = root,
	$cmd, 
	$args="",
	$ensure = present	

){
	$_wait = $wait ? {
		true => 'wait',
		default => 'nowait'
	}
	$line = "$name\t$socket_type\t$protocol\t$_wait\t$user\t$cmd\t$args"

	if $ensure == absent {
		$c="#"
	}
	else {
		$c=""
	}
	
	$tm = "^#{0,}${service_name}[[:blank:]]${socket_type}[[:blank:]]${protocol}[[:blank:]]"

	file_line { "$mailserver::inetd::conf - $title":
		ensure   => present,
		path     => $mailserver::inetd::conf,
		line     => "$c$line",
		match    => $tm,
		notify	=> Service[$mailserver::inetd::service],
	}

}


