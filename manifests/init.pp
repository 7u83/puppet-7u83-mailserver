# Class: mailserver
# ===========================
#
# Install a mail server using Postfix, Dovecot, Clamav, Opendkim, 
# and extras like Sympa, Rspamd, Sieve and more 
#
# Parameters
# ----------
#
# Document parameters here.
#
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#"
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'mailserver':
#      services => [ 'imap', 'submission' ],
#    }
#
# Authors
# -------
#
# 7u83 <7u83@mail.ru>
#
# Copyright
# ---------
#
# Copyright 2018 7u83.
#
class mailserver (
	#
	# general
	#
	$myhostname = "localhost",
	$mydestination = undef,
	$myorigin = undef,


	$localhost = "127.0.0.1",
	$mynetworks = ["127.0.0.1/32"],

	$local_userdb = ["passwd"],

	$srs_domain = undef,
	$srs_exclude_domains = undef,

	#
	# MYSQL
	#
	$mysql = false,	
	$mysql_mail_search = "",

	$mysql_password_query = "",
	$mysql_user_query = "",
	$mysql_login_maps_query ="",

	$mysql_server = "",
	$mysql_user = "",
	$mysql_db = "",
	$mysql_password = "",
	

	#
	# LDAP
	#


	$ldap = false,
	$ldap_auth_bind="no",
	$ldap_base="",


	$ldap_login_search="(&(objectClass=posixAccount)(uid=%s))",
	$ldap_mail_search="(&(objectClass=posixAccount)(mail=%s))",

	$ldap_uid_attribute="uid",
	$ldap_maildir_attribute="uid",

	#
	# SPAM
	#

	$spam_reject_score = undef,
	$spam_greylist_score = undef,
	$spam_add_header_score = undef,



#	$ldap_homedir_attribute,

	
	$transport_maps = '',

#	$ldap_pass_filter="(&(objectClass=posixAccount)(uid=%u))",
#	$ldap_user_filter="(&(objectClass=posixAccount)(uid=%u))",


#	$ldap_login_maps_query=undef,
#	$ldap_login_maps_result_attribute=undef,

	$ldap_hosts = [],
	$ldap_dn = undef,
	$ldap_pass = undef,

	$ldap_uid_attrib = "uid",
	$ldap_homedir_attrib = "homeDirectory",


	$vmail_user="vmail", 
	$vmail_group="vmail",


	$mail_location = "mbox",


	#
	# ClamAV
	#
	$clamav_infected_action = "Reject",


	$solr = false,
	$lucene=false,

	$dovecot_listen = "*",
	
	$imap = true,
	$pop3 = true,
	$impas = true,
	$smtp = true,
	

	$auth_system = true,

	#
	# SSL 
	#
	$smtp_hostname = undef,
	$smtp_sslcert = undef,
	$smtp_sslkey = undef,

	$submission_hostname = undef,
	$submission_sslcert = undef,
	$submission_sslkey = undef,

	$imap_hostname = undef,
	$imap_sslcert = undef,
	$imap_sslkey = undef,

	$sslcert_src = "puppet:///ssl",	

	# 
	# DKIM params
	#
	$dkim_selector = undef,
	$dkim_domains = undef,
	$dkim_source = "puppet:///dkim",



	#
	# Sympa parameters
	#
	$sympa_db_host = undef,
	$sympa_db_name = "sympa",
	$sympa_db_user = "sympa",
	$sympa_db_passwd = "sympa",
	$sympa_fcgi_addr = false,
	$sympa_fcgi_port = "9000",
	$sympa_web_location = "/sympa",
	$sympa_static_web_location = "/static-sympa",
	$sympa_virtual = false,
	$sympa_domain = undef,
	$sympa_log_level = false,

	$sympa_virtual_domains = [],
	$sympa_title = undef,
	$sympa_gecos = undef, 

	$sympa_logo_html_definition = false,

	$lists_listmaster = undef,
	$lists_web_url = undef,
	$lists_dmarc_protection_mode = "reject",

	$default_destination_rate_delay = "1s",

	$mailbox_size_limit = 0,
	$message_size_limit = 26214400,


	$virtual_userdb = ["ldap","mysql"],

	$virtual_mailbox_domains = [],
	$virtual_mailbox_base = "/mail",
	$virtual_alias_maps = [],
	$virtual_mailbox_maps = [],
	$virtual_maps_src = undef,
	$virtual_maps_dir = undef,
	$virtual_mailbox_format = "maildir",
	$virtual_mailbox_dir = "Maildir",

	

	$services = ["smtp","submission","imap"],

	$tls_security = "encrypt",



	#
	# SMTP parameters + defaults
	#
	$submission_verify_recipient = false,
	$smtp_rbls = [],
	$smtp_client_restrictions = [
		"permit_mynetworks",
		"reject_unknown_reverse_client_hostname",
		"reject_unauth_pipelining"
	],
	$smtp_recipient_restrictions = [
		"permit_mynetworks",
		"reject_unlisted_recipient",
		"reject_unauth_destination",
		"reject_unknown_recipient_domain",
	],
	$smtp_helo_restrictions = [
		"permit_mynetworks",
		"reject_invalid_hostname",
		"reject_unknown_hostname",
		"reject_non_fqdn_hostname",
	],
	$smtp_relay_restrictions = [
		"permit_mynetworks",
		"defer_unauth_destination"
	],
	$smtp_milters = [],
	$smtp_postscreen = false,
	$smtp_postscreen_rbls = undef,



	#
	# Submission parameters + defaults
	#

	$submission_rbls = [],
	$submission_client_restrictions = [
		"permit_sasl_authenticated",
		"reject"
	],
	$submission_recipient_restrictions = [
		"reject_unknown_recipient_domain",
		"permit_sasl_authenticated",
		"reject",
	],
	$submission_helo_restrictions = [
		"permit_sasl_authenticated",
		"reject",
	],
	$submission_relay_restrictions = [
		"permit_sasl_authenticated",
		"reject",
	],
	$submission_sender_restrictions = [
		"reject_authenticated_sender_login_mismatch",
		"permit_sasl_authenticated",
		"reject",
	],

	$submission_milters = [],
	$submission_mynetworks = [],

	$extra_login_maps=[],



) inherits mailserver::params {

	$_transport_maps = $transport_maps

	# ----------------------------------------------------------------
	# Basic setup
	#

	$_myorigin = $myorigin ? {
		undef => $myhostname,
		default => $myorigin,
	}

	$_mydestination = $mydestination ? {
		undef => $_myorigin,
		default => join($mydestination," ")
	}

	$_imap_hostname = $imap_hostname ? {
		undef => $myhostname,
		default => $imap_hostname,
	}

	$_smtp_hostname = $smtp_hostname ? {
		undef => $myhostname,
		default => $smtp_hostname,
	}

	$_submission_hostname = $submission_hostname ? {
		undef => $myhostname,
		default => $submission_hostname,
	}


	$_mynetworks = join($mynetworks," ")


	$dovecot_services = concat ( intersection (["imap","pop3","imaps","pop3s","sieve" ],$services), "lmtp" )
	if "sieve" in $dovecot_services {
		$mailbox_command = $dovecot_deliver
	}

	if $smtp_postscreen { 
		if $smtp_postscreen_rbls == undef {
			$_postscreen_rbls = join ( $smtp_rbls , " ") 
		}
		else {
			$_postscreen_rbls = $smtp_postscreen_rbls
		}
	}
	else{
		$_postscreen_rbls = undef
	}
	


	if "mysql" in $virtual_userdb  and $mysql {
		$_virtual_mysql_mailbox_maps = "mysql:$postfix_dir/mysql_vmbox_maps.cf"
		mailserver::postfix_mysqlmap{ "mysql_vmbox_maps.cf":
			dbuser => $mysql_user,	
			password => $mysql_password,
			dbname => $mysql_db,
			server => $mysql_server,
			query => $mysql_mail_search,
		}
		$_virtual_mysql_alias_maps = ["mysql:$postfix_dir/mysql_valias_maps.cf"]

		mailserver::postfix_mysqlmap{ "mysql_valias_maps.cf":
			dbuser => $mysql_user,	
			password => $mysql_password,
			dbname => $mysql_db,
			server => $mysql_server,
			query => $mysql_mail_search,
		}

		$_mysql_login_maps = ["mysql:$postfix_dir/mysql_login_maps.cf"]
		mailserver::postfix_mysqlmap{ "mysql_login_maps.cf":
			dbuser => $mysql_user,	
			password => $mysql_password,
			dbname => $mysql_db,
			server => $mysql_server,
			query => $mysql_login_maps_query,
		}


	}
	else {
		$_virtual_mysql_alias_maps = []
		$_mysql_login_maps = []
	}
	

	if "ldap" in $virtual_userdb  and $ldap {
		$_virtual_ldap_mailbox_maps = "ldap:$postfix_dir/ldap_vmbox_maps.cf"

		if $virtual_mailbox_format == "maildir"{
			$result_format = "%s/$virtual_mailbox_dir/"
		}
		else{
			$result_format ="%s"
		}

		mailserver::postfix_ldapmap{ "ldap_vmbox_maps.cf":
			query_filter => $ldap_mail_search,
			result_attribute => $ldap_maildir_attribute,
			result_format => $result_format,
		}


		$_virtual_ldap_alias_maps = ["ldap:$postfix_dir/ldap_valias_maps.cf"]
		mailserver::postfix_ldapmap{ "ldap_valias_maps.cf":
			query_filter => $ldap_mail_search,
			result_attribute => "mailForwardAddress",
#			result_format => $result_format,
		}




#		$_virtual_mailbox_maps = "ldap:$postfix_dir/ldap_login_maps.cf"
	}
	else {
		$_virtual_ldap_alias_maps = []
	}
	



	# ----------------------------------------------------------------
	# Virtual setup
	#

	
	$_virtual_mailbox_domains = join($virtual_mailbox_domains," ")

	if $virtual_mailbox_domains != [] {
		user {"$vmail_user":
			ensure => present,
			uid => "400",
		}

		group {"$vmail_group":
			ensure => present,
			gid => "400",
		}

		file {"$virtual_mailbox_base":
			ensure => directory,
			owner => "$vmail_user",
			require => User["$vmail_user"],
		}



		mailserver::postfix_hashmap{"valiases":
			source => undef,
			path => "$postfix_dir"
		}

		mailserver::postfix_hashmap{"vmboxes":
			source => undef,
			path => "$postfix_dir"
		}

		$_virtual_alias_maps = join( concat( 
					["hash:$postfix_dir/valiases"],
					$virtual_alias_maps.map|$elem|{ "hash:$aliasmaps_dir/$elem"},
					$_virtual_mysql_alias_maps,
					$_virtual_ldap_alias_maps			
				), " ")


		$_virtual_mailbox_maps = join( concat( 
					["hash:$postfix_dir/vmboxes"],
					$virtual_mailbox_maps.map|$elem|{ "hash:$aliasmaps_dir/$elem"},
					["$_virtual_mysql_mailbox_maps"],
					["$_virtual_ldap_mailbox_maps"],
					["$transport_maps"],
				), " ")


		$virtual_alias_maps.each | String $file | {
			mailserver::postfix_hashmap{"$file":
				source => "puppet:///mail",
				path => $aliasmaps_dir
			}
			
		}

		$virtual_mailbox_maps.each | String $file | {
			mailserver::postfix_hashmap{"$file":
				source => "puppet:///mail",
				path => $aliasmaps_dir
			}
			
		}

		$extra_login_maps.each | String $file | {
			mailserver::postfix_hashmap{"$file":
				source => "puppet:///mail",
				path => $aliasmaps_dir
			}
			
		}
#join( concat([], 

		$_extra_login_maps = $extra_login_maps.map|$elem|{ "hash:$aliasmaps_dir/$elem"}
#				), " ")



	}
	else{
		$_extra_login_maps = []
	}

	
	# ----------------------------------------------------------------
	# SRS Setup
	#
	if $srs_domain != undef {
		if $srs_exclude_domains == undef{
			$_srs_exclude_domains = concat (concat ($virtual_mailbox_domains,
							$mydestination ? {
								undef => [],
								default => $mydestination
							}), $myhostname )
		}
		else {
			$srs_exclude_domains = $srs_exclude_domains
		}

		class {"mailserver::postsrsd":
			srs_domain => $srs_domain,
			srs_exclude_domains => $_srs_exclude_domains,
		}
	}

		


	# ----------------------------------------------------------------
	# SSL setup
	#
	
	if $imap_sslcert == undef {
		$_imap_sslcert  = "$ssldir/$_imap_hostname/fullchain.pem"
		$imap_sslcert_src = $sslcert_src
	}
	else {
		$_imap_sslcert  = $imap_sslcert
		$imap_sslcert_src = undef
	}
	
	if $imap_sslkey == undef {
		$_imap_sslkey  = "$ssldir/$_imap_hostname/privkey.pem"
		$imap_sslkey_src = $sslcert_src
	}
	else {
		$_imap_sslcert  = $imap_sslcert
		$imap_sslkey_src = undef
	}
	
	if $imap_sslcert_src != undef {
		ensure_resource ("mailserver::copyfile","fullchain.pem",{
			path => "$ssldir/$_imap_hostname",
			source => "$imap_sslcert_src/$_imap_hostname",
		})
	}
	if $imap_sslkey_src != undef {
		ensure_resource ("mailserver::copyfile","privkey.pem",{
			path => "$ssldir/$_imap_hostname",
			source => "$imap_sslcert_src/$_imap_hostname",
		})
	}

	if $smtpd_sslcert == undef {
		$_smtpd_sslcert  = "$ssldir/$_smtp_hostname/fullchain.pem"
		$smtpd_sslcert_src = $sslcert_src
	}
	else {
		$_smtpd_sslcert  = $smtpd_sslcert
		$smtpd_sslcert_src = undef
	}
	
	if $smtpd_sslkey == undef {
		$_smtpd_sslkey  = "$ssldir/$_smtp_hostname/privkey.pem"
		$smtpd_sslkey_src = $sslcert_src
	}
	else {
		$_smtpd_sslcert  = $smtpd_sslcert
		$smtpd_sslkey_src = undef
	}
	
	if $smtpd_sslcert_src != undef {
		ensure_resource("mailserver::copyfile","fullchain.pem",{
			path => "$ssldir/$_smtp_hostname",
			source => "$smtpd_sslcert_src/$_smtp_hostname",
		})
	}
	if $smtpd_sslkey_src != undef {
		ensure_resource ("mailserver::copyfile", "privkey.pem",{
			path => "$ssldir/$_smtp_hostname",
			source => "$smtpd_sslcert_src/$_smtp_hostname",
		})
	}



	# ----------------------------------------------------------------
	# DKIM Setup
	#

	if $dkim_selector != undef {
		ensure_resource ("class","mailserver::postfix",{
			ldap  => $ldap,
			mysql => $mysql, 
		})
		if $dkim_domains == undef {
			$_dkim_domains = "*"  #$myorigin
		}
		else {
			$_dkim_domains = $dkim_domains
		}

		class {"mailserver::opendkim":
			selector => $dkim_selector,
			domains => $_dkim_domains,

			dkim_source => $dkim_source,
			mynetworks => $mynetworks
		}
		service {"$::mailserver::opendkim::service":
			ensure => "running",
			subscribe => Class["mailserver::opendkim"],
			require => Class["mailserver::postfix"],
		}

	}

	
	# ----------------------------------------------------------------
	# DMARC Setup
	#

	Class["mailserver::opendmarc"] -> Class["::mailserver::postfix"]
	
	class {"mailserver::opendmarc":
		umask => "0111",
		reject_failures => true,
		software_header => true,
		spf_self_validate => true,
	}
	
	$dmarc_milter_socket = "unix:$::mailserver::opendmarc::milter_socket"


	#
	# RSPAMD Setup
	#

	class {"mailserver::rspamd":
		reject_score => $spam_reject_score,
		greylist_score => $spam_greylist_score,
		add_header_score => $spam_add_header_score,
	}	

	$rspamd_milter_socket = "unix:$::mailserver::rspamd::milter_socket"

	# ----------------------------------------------------------------
	# SMTP Server
	#



	if $ldap_lmtp_user_filter != undef {
		$_ldap_lmtp_user_filter = $ldap_lmtp_user_filter
	}
	else{
		$_ldap_lmtp_user_filter = $ldap_user_filter
	}


	if "passwd" in $local_userdb {
		$passwd_login_maps = "$postfix_dir/passwd_login_maps.cf"
		file { "$passwd_login_maps":
			ensure => present,
			content => '/^(.*?):\*/     $1',
			require => Class["mailserver::postfix"],
			notify => Service["$postfix_service"],
		}
		$sender_passwd_login_maps = 'pipemap:{proxy:unix:passwd.byname,pcre:/usr/local/etc/postfix/passwd_login_maps.cf}'
	}








	# ----------------------------------------------------------------
	# SMTP Server
	#

	if "smtp" in $services {
		ensure_resource ("class","mailserver::postfix",{
			ldap  => $ldap
		})

		class {"mailserver::mx":
			rbls => $smtp_rbls,
			client_restrictions => $smtp_client_restrictions,
			recipient_restrictions => $smtp_recipient_restrictions,
			helo_restrictions =>  $smtp_helo_restrictions ,
			relay_restrictions => 	$smtp_relay_restrictions,
			milters => $smtp_milters,
			postscreen => $smtp_postscreen,

		}
	}


	# ----------------------------------------------------------------
	# Suubmission Server
	#
	if "submission" in $services {	
		ensure_resource ("class","mailserver::postfix",{
			ldap  => $ldap
		})
		if $ldap {
			$sender_login_maps = [
				"ldap:$postfix_dir/ldap_login_maps.cf"
			]
		}
		else {
			$sender_login_maps = []
		}


		class {"mailserver::submission":
			sender_login_maps => concat ( $_extra_login_maps, $sender_login_maps, $sender_passwd_login_maps, $_mysql_login_maps), #$_virtual_alias_maps),
			verify_recipient => $submission_verify_recipient,
			rbls => $submission_rbls,
			client_restrictions => $submission_client_restrictions,
			recipient_restrictions => $submission_recipient_restrictions,
			helo_restrictions => $submission_helo_restrictions,
			relay_restrictions => $submission_relay_restrictions,
			sender_restrictions => $submission_sender_restrictions,
			milters => $submission_milter,
		}
	}





	# ----------------------------------------------------------------
	# Sympa 
	#
	if "sympa" in $services {
		$sympa = true

		# init some defaults for sympa
	
		class {"mailserver::sympa":
			domain => $sympa_domain ? {
					undef => $_myorigin,
					default => $sympa_domain,
			},
			db_user => $sympa_db_user,
			db_passwd => $sympa_db_passwd,
			db_name =>  $sympa_db_name,
			db_host => $sympa_db_host,
			
			stitle => $sympa_title,
			
			logo_html_definition => $sympa_logo_html_definition,

			listmaster => $lists_listmaster,
			web_url => $lists_web_url,

			static_web_location => $sympa_static_web_location,	
			web_location => $sympa_web_location,
			localhost => $localhost,

			virtual => $sympa_virtual,
			virtual_domains => $sympa_virtual_domains,
			dmarc_protection_mode => $lists_dmarc_protection_mode,
	
			gecos => $sympa_gecos,			

		}

		if $sympa_virtual {
			$_virtual_sympa_mailbox_maps = "hash:$::mailserver::sympa::sympa_transport_sympa hash:$::mailserver::sympa::sympa_transport"
		}
		else {
			$sympa_aliases = $::mailserver::sympa::sympa_aliases
			$sympa_sendmail_aliases = $::mailserver::sympa::sympa_sendmail_aliases
		}


	}








#	notify {"$_smtpd_sslkey":}












	if $mail_location == "mbox" {
		$dovecot_mail_location = "mbox:~/mail:LAYOUT=maildir++:INBOX=/var/mail/%u:INDEX=~/mail/index:CONTROL=~/mail/control"
	}elsif $mail_location == "maildir" {
		$dovecot_mail_location = "maildir:~/Mail"
	}else {
		$dovecot_mail_location = $mail_location
	}

	$non_smtpd_milters = join([
		$::mailserver::clamav::milter_sock,
		$::mailserver::opendkim::milter_sock,
		
	]," ")


		
#	class {"mailserver::install_postfix":
#		ldap => $ldap
#	}
	ensure_resource ("class","mailserver::postfix",{
		ldap  => $ldap
	})

	class {"mailserver::clamav":
		ldap => $ldap
	}


	class {"mailserver::install_dovecot":
		local_userdb => $local_userdb,
		mysql=>$mysql,
		mysql_user_query => $mysql_user_query,
		mysql_password_query => $mysql_password_query,

		ldap=>$ldap,
		ldap_base => $ldap_base,
		ldap_pass_filter => $ldap_pass_filter,
		ldap_user_filter => $ldap_user_filter,
		ldap_lmtp_user_filter => $_ldap_lmtp_user_filter, 
		ldap_auth_bind => $ldap_auth_bind,
		ldap_dn => $ldap_dn,
		ldap_pass => $ldap_pass,
		ldap_hosts => $ldap_hosts,

		solr=>$solr,
		lucene => $lucene,
		listen => $dovecot_listen, 
		mail_location => $dovecot_mail_location,
		disable_plaintext_auth => $tls_security == "encrypt", #$disable_plaintext_auth,

		auth_system => $auth_system,

		imap_sslcert => $_imap_sslcert,
		imap_sslkey => $_imap_sslkey,

		virtual_mailbox_base => $virtual_mailbox_base,
		ldap_login_maps_result_attribute => $ldap_login_maps_result_attribute,

#		vmail_user => $vmail_user,
#		vmail_group = $vmail_group,

		protocols => $dovecot_services,
	}



	file { "$postfix_main_cf":
		ensure => present,
		content => template("mailserver/postfix-main.conf.erb"),
		require => [
			Class["mailserver::postfix"]
		]
	}


	file {"/usr/local/etc/postfix/header_checks":
		ensure => present,
		content => "/^Received: .*\(Authenticated sender:.*/ IGNORE
/^Received: by mailing\.wikimedia\.de .*from userid [0-9]+\)/ IGNORE
/^User-Agent:/ IGNORE
/^X-Originating-IP:/ IGNORE
",
		require => [
			Class["mailserver::postfix"]
		]

	}

	service { "$postfix_service":
		ensure => running,
		require => Concat["$postfix_master_cf"],
		subscribe => [Concat["$postfix_master_cf"], File["$postfix_main_cf"], File["$postfix_dir/ldap_login_maps.cf"]]
		
	}

	concat { "$postfix_master_cf": 
		ensure => present,
		require => [
			Class["mailserver::postfix"],
			Class["mailserver::clamav"]
		]
	}

	concat::fragment { "$postfix_master_cf header":
		target => "$postfix_master_cf",
		order => '00',
		content => template('mailserver/postfix-master-header.conf.erb'),
	}


	mailserver::postfix_ldapmap{ "ldap_login_maps.cf":
		query_filter => $ldap_mail_search,
		result_attribute => $ldap_uid_attribute
			
	}





	service {"$dovecot_service":
		ensure => running,
		subscribe => Class["mailserver::install_dovecot"],
		require => [Class["mailserver::install_dovecot"],File["$ssldir/$_imap_hostname/fullchain.pem"],File["$ssldir/$_imap_hostname/privkey.pem"]]
#
#
	}

#	mailserver::install_sslcert {"$myhostname":
#		owner => postfix
#	}



}	

define mailserver::copyfile(
	$source,
	$path ,
	
)
{
	exec { "mkdir $path for $title":
		command => "/bin/mkdir -p $path",
		creates => "$path"
	}

	file { "$path/$title":
		ensure => file,
		source => "$source/$title",
		require => Exec["mkdir $path for $title"],
	} 
}


define mailserver::postfix_hashmap(
	$source = undef,
	$path 

){
	if $source != undef {
		ensure_resource ("mailserver::copyfile",$title,{
			path => "$path",
			source => "$source",
		})
	}
	else{
		file{ "$path/$title":
			ensure => present
		}
	}
	

	exec { "$mailserver::params::postmap_cmd $path/$title":
		#creates => "$path/$title.db",
		refreshonly => true,
		require => File["$path/$title"],
		subscribe => File["$path/$title"],
	}	

}






define mailserver::install_sslcert (
	$source=undef,
	$owner,
) 
{
	$etcdir = $::mailserver::params::etcdir

	if $source == undef {
		$chainsource = "puppet:///ssl/$title/fullchain.pem"
		$keysource = "puppet:///ssl/$title/privkey.pem"
	}
	else {
		$chainsource = "$source/$title/fullchain.pem"
		$keysource = "$source/$title/privkey.pem"
	}


	file  {"$etcdir/ssl":
		ensure => directory
	}

	file {"$etcdir/ssl/$title":
		ensure => directory,
		require => File["$etcdir/ssl"]
	}

	file {"$etcdir/ssl/$title/fullchain.pem":
		ensure => present,
		source => $chainsource,
		require => File["$etcdir/ssl/$title"],
	}

	file {"$etcdir/ssl/$title/privkey.pem":
		ensure => present,
		source => $keysource,
		require => File["$etcdir/ssl/$title"],
	}

}



define mailserver::service(
	$service,
	$type = 'inet',
	$private = 'n',
	$unpriv = '-',
	$chroot = 'n',
	$wakeup = '-',
	$maxproc = '-',
	$command, 
	$args = [],
){
	concat::fragment  { "$title":
		target => "$::mailserver::params::postfix_master_cf",
		content => template("mailserver/postfix-master-service.conf.erb");
	}	
}




define mailserver::postfix_mysqlmap(
	$query,
	$server,
	$password,
	$dbuser,
	$dbname,
){
	file {"$::mailserver::params::postfix_dir/$title":
		ensure => present,
		notify => Service["$::mailserver::params::postfix_service"],
		content => "hosts = $server
dbname = $dbname
user = $dbuser
password = $password
query = $query
"
	}
}

define mailserver::postfix_ldapmap(
	$query_filter,
	$result_attribute,
	$result_format=undef,
){
	if $result_format != undef {
		$rf = "\nresult_format=$result_format"
	}
	else {
		$rf = ""
	}

	
	

	$_ldap_hosts = join($mailserver::ldap_hosts," ")
	file {"$::mailserver::params::postfix_dir/$title":
		ensure => present,
		notify => Service["$::mailserver::params::postfix_service"],
		content => "bind=yes
bind_dn=$::mailserver::ldap_dn
bind_pw=$::mailserver::ldap_pass
search_base=$::mailserver::ldap_base
server_host=$_ldap_hosts
version=3
query_filter=$query_filter
result_attribute=$result_attribute$rf
"
	}
}



class mailserver::mx(
	$rbls = [],

	$client_restrictions = [
		"permit_mynetworks",
		"reject_unknown_reverse_client_hostname",
		"reject_unauth_pipelining"
	],
	$recipient_restrictions = [
		"permit_mynetworks",
		"reject_unverified_recipient",
		"reject_unauth_destination"
	],
	$helo_restrictions = [
		"permit_mynetworks",
		"reject_invalid_hostname",
		"reject_unknown_hostname",
		"reject_non_fqdn_hostname",
	],
	$relay_restrictions = [
		"permit_mynetworks",
		"defer_unauth_destination"
	],

	$milters = [],

	$mynetworks = [],

	$postscreen = false,

	$tls_security = "may",


)inherits mailserver{

	$pfrbls = join ( $rbls.map|$elem|{ "reject_rbl_client $elem"} , " ") 

	$pfclient_restrictions = join($client_restrictions," ")
	$pfrecipient_restrictions = join($recipient_restrictions," ")
	$pfhelo_restrictions = join($helo_restrictions, " ")
	$pfrelay_restrictions =  join($relay_restrictions, " ")

	$pflmilters = join([
		$rspamd_milter_socket,
#		$dmarc_milter_socket,
		$mailserver::clamav::milter_sock,
#		$opendkim_milter_sock,
	]," ")

	$pfmilters = join($milters," ")
	$pfmynetworks = join($mynetworks," ")


	if $postscreen {
		mailserver::service{ "Postscreen":
			service => 'smtp',
			command => 'postscreen',
			maxproc => 1,
			args => [],
		}

		$chroot = '-'
		$private = '-'
		$service = 'smtpd'
		$type = 'pass'

	}
	else {
		$chroot = 'n'
		$private = 'n'
		$service = 'smtp'
		$type = 'inet'
	}

	$kf = $::mailserver::_smtpd_sslkey
	
	if $tls_security != false {
		$ssl_options ="{ -o smtpd_tls_security_level = $tls_security }
	{ -o smtp_tls_note_starttls_offer = yes }
	{ -o smtpd_tls_key_file = $kf }
	{ -o smtpd_tls_cert_file = $::mailserver::_smtpd_sslcert }
	{ -o smtpd_tls_loglevel = 1 }
	{ -o smtpd_tls_received_header = yes }
	{ -o smtpd_tls_session_cache_timeout = 3600s }"
	}
	else{
		$ssl_options = ""
	}


	mailserver::service{ "Postfix SMTP Server":
		service => $service,
		command => 'smtpd',
		type => $type,
		private => $private,
		chroot => $chroot,
		args => [
			"{ -o smtpd_recipient_restrictions = $pfrecipient_restrictions $pfrbls }",
			"{ -o smtpd_client_restrictions = $pfclient_restrictions }",
			"{ -o smtpd_helo_restrictions = $pfhelo_restrictions }",
			"{ -o smtpd_relay_restrictions = $pfrelay_restrictions }",
			"{ -o smtpd_milters = $pflmilters $pfmilters}",
			"{ -o smtpd_sasl_auth_enable = no }",
		        "{ -o smtpd_tls_mandatory_ciphers = high}",
			"{ -o tls_ssl_options = 0x40000000}",
		        "{ -o tls_preempt_cipherlist = yes}",
		        "{ -o smtpd_tls_eecdh_grade = ultra}",
			"$ssl_options",
		]

	}

#	mailserver::service{ "Dovecot for $hostname":
#		service => dovecot,
#		type => "unix",
#		private =>'-',
#		unpriv => 'n',
#		chroot => 'n',
#		wakeup => '-',	
#		maxproc => '-',
#		command => "pipe",
#		args => [
#			"flags=DRhu user=vmail:vmail argv=$dovecot_lda -f \${sender} -d \${recipient}",
#		]
#
#	}


}





class mailserver::submission(
	$rbls = [],

	$client_restrictions = [
		"permit_sasl_authenticated",
		"reject"
	],
	$recipient_restrictions = [
		"reject_unknown_recipient_domain",
		"permit_sasl_authenticated",
		"reject",
	],
	$helo_restrictions = [
		"permit_sasl_authenticated",
		"reject",
	],
	$relay_restrictions = [
		"permit_sasl_authenticated",
		"reject",
	],
	$sender_restrictions = [
		"reject_authenticated_sender_login_mismatch",
		"permit_sasl_authenticated",
		"reject",
	],

	$tls_security = 'encrypt',

	$milters = [],

	$mynetworks = [],

	$ldap_login_map =[],


	$verify_recipient = false,

	$sender_login_maps = [],

	$smtps=false,

)inherits mailserver{

	$pfclient_restrictions = join($client_restrictions," ")

	if $verify_recipient {
		$_reject_unverified_recipient = "reject_unverified_recipient"
	}
	
	$pfrecipient_restrictions = join(
			concat($recipient_restrictions,$_reject_unverified_recipient),
			" ")

	if $smtps {
		$subservice = "smtps"
		$wrapper_mode = "yes"
	}
	else {
		$subservice = "submission"
		$wrapper_mode = "no"
	}


	$pfhelo_restrictions = join($helo_restrictions, " ")
	$pfrelay_restrictions =  join($relay_restrictions, " ")
	$pfsender_restrictions = join($sender_restrictions, " ")

	
	$_sender_login_maps = join($sender_login_maps, " ")

	$pflmilters = join([
		$rspamd_milter_socket,
		$mailserver::clamav::milter_sock,
		$mailserver::opendkim::milter_sock,
	]," ")

	$pfmilters = join($milters," ")
#	$pfmynetworks = join($mynetworks," ")

	$kf = $::mailserver::_smtpd_sslkey

	if $tls_security != false {
		$ssl_options ="{ -o smtpd_tls_security_level = $tls_security }
	{ -o smtpd_tls_key_file = $kf }
	{ -o smtpd_tls_cert_file = $::mailserver::_smtpd_sslcert }
	{ -o smtpd_tls_loglevel = 1 }
	{ -o smtpd_tls_received_header = yes }
	{ -o smtpd_tls_session_cache_timeout = 3600s }
        { -o smtpd_tls_mandatory_ciphers = high}
	{ -o tls_ssl_options = 0x40000000}
        { -o tls_preempt_cipherlist = yes}
        { -o smtpd_tls_eecdh_grade = ultra}
	{ -o smtpd_tls_auth_only = yes }"

	$offer_start_tls = "{ -o smtp_tls_note_starttls_offer = yes }"
	$tls_wrapper = "{ -o smtpd_tls_wrappermode=yes }"
	}
	else{
		$ssl_options = ""
	}

	mailserver::service{ "Postfix Subimission":
		service => "submission",
		command => 'smtpd',
		args => [
			"{ -o smtpd_sender_restrictions = $pfsender_restrictions }",
			"{ -o smtpd_recipient_restrictions = $pfrecipient_restrictions }",
			"{ -o smtpd_client_restrictions = $pfclient_restrictions }",
			"{ -o smtpd_helo_restrictions = $pfhelo_restrictions }",
			"{ -o smtpd_relay_restrictions = $pfrelay_restrictions }",
			"{ -o smtpd_milters = $pflmilters $pfmilters}",
			"{ -o smtpd_sasl_auth_enable = yes }",
			"{ -o smtpd_sasl_type = dovecot }",
			"{ -o smtpd_sasl_path = /var/spool/postfix/private/auth }",
			"{ -o smtpd_sender_login_maps = $_sender_login_maps }",
			"$ssl_options",
			"$offer_start_tls",
		]
	}

	mailserver::service{ "Postfix SMTPS":
		service => "smtps",
		command => 'smtpd',
		args => [
			"{ -o smtpd_sender_restrictions = $pfsender_restrictions }",
			"{ -o smtpd_recipient_restrictions = $pfrecipient_restrictions }",
			"{ -o smtpd_client_restrictions = $pfclient_restrictions }",
			"{ -o smtpd_helo_restrictions = $pfhelo_restrictions }",
			"{ -o smtpd_relay_restrictions = $pfrelay_restrictions }",
			"{ -o smtpd_milters = $pflmilters $pfmilters}",
			"{ -o smtpd_sasl_auth_enable = yes }",
			"{ -o smtpd_sasl_type = dovecot }",
			"{ -o smtpd_sasl_path = /var/spool/postfix/private/auth }",
			"{ -o smtpd_sender_login_maps = $_sender_login_maps }",
			"$ssl_options",
			"$tls_wrapper",
		]
	}

}














#	if $mailman3 == true {
#		ensure_resource ("class","mailserver::install_postfix",{
#			ldap  => $ldap
#		})
#		Class["mailserver::install_mailman3"] -> Class["mailserver::mailman_service"] 
#
#		class {"mailserver::install_mailman3":
#			remove_dkim => $mailman_remove_dkim
#		}
#		class {"mailserver::mailman_service":}
#		$mailman_local_maps = "hash:$mailman_vardir/data/postfix_lmtp"
#	}
	








