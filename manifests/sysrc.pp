


define mailserver::sysrc (
	$ensure 
){

	exec {"/usr/sbin/sysrc '$title=$ensure'":
		unless => "/usr/sbin/sysrc -c '$title=$ensure'"
	}

}
