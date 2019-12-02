$g_config = @{
	db_host = 'mysqldb.contoso.com';
	db_name = 'nbt';
	db_user = 'root';
	db_passwd = 'passw0rd';
	smtp_login = 'contoso\orchestrator';
	smtp_passwd = 'Passw0rd';
	smtp_from = 'nb@contoso.com';
	smtp_to = @('admin@contoso.com', 'hd@contoso.com');
	smtp_server = 'smtp.contoso.com';
	restore_server = 'SRV-NBTEST-01';
	backup_server = 'srv-nb-01.contoso.com';
}
