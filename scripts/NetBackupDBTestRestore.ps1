# Run restore test for marked images

# Flags
# 0x01 = WAIT FOR TEST
# 0x02 = TESTED OK
# 0x04 = FAILED CHECKDB
# 0x08 = FAILED RESTORE
# 0x10 = RESTORE IN PROGRESS    For reset this status: "UPDATE nbt_images SET `flags` = (`flags` & ~0x10) WHERE `flags` & 0x10"
# 0x20 = NOT FOUND
# 0x40 = CHECKDB IN PROGRESS

$ErrorActionPreference = "Stop"

$smtp_from = "orchestrator@contoso.com"
$smtp_to = @("admin@contoso.com", "systems@contoso.com")
$smtp_server = "smtp.contoso.com"

$smtp_creds = New-Object System.Management.Automation.PSCredential ("", (ConvertTo-SecureString "" -AsPlainText -Force))


$mdf_template = @'
MOVE  "{0}"
TO  "F:\Workdata\NB_Test_Restore_{1}.mdf"

'@

$log_template = @'
MOVE  "{0}"
TO  "F:\Workdata\NB_Test_Restore_log_{1}.ldf"

'@

$bch_template = @'
OPERATION RESTORE
OBJECTTYPE DATABASE
RESTORETYPE MOVE
DATABASE "NB_Test_Restore"
{0}
{1}
NBIMAGE "{2}"
SQLHOST "srv-NBTEST-01"
SQLINSTANCE "MSSQLSERVER"
NBSERVER "srv-NB-01.contoso.com"
#STRIPES {3:d3}
STRIPES 001
BROWSECLIENT "{4}"
MAXTRANSFERSIZE 6
BLOCKSIZE 7
RESTOREOPTION REPLACE
RECOVEREDSTATE RECOVERED
NUMBUFS 2
ENDOPER TRUE
'@

$header = @'
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<style>
		body{font-family: Arial; font-size: 8pt;}
		h1{font-size: 16px;}
		h2{font-size: 14px;}
		h3{font-size: 12px;}
		table{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}
		th{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
		td{border: 1px solid black; padding: 5px; }
		.pass {background: #7FFF00;}
		.warn {background: #FFE600;}
		.error {background: #FF0000; color: #ffffff;}
	</style>
</head>
<body>
'@


$ErrorActionPreference = "Stop"

function Log-Only($severity, $message)
{
	if($severity -eq "error")
	{
		$s = "ERROR:  "
	}
	elseif($severity -eq "warn")
	{
		$s = "WARNING:"
	}
	elseif($severity -eq "pass")
	{
		$s = "OK:     "
	}
	else
	{
		$s = "INFO:     "
	}

	try
	{
		Out-File -Append -Encoding utf8 -FilePath "c:\scripts\logs\NetBackupTestRestore.log" -InputObject ("{1:yyyy-MM-dd HH:mm:ss}    {2} {0}" -f $message, [DateTime]::Now, $s)
	}
	catch
	{
		Write-Host -ForegroundColor Red $_.Exception.Message
	}
}

function Log-Screen($severity, $message)
{
	if($severity -eq "error")
	{
		$s = "ERROR:  "
		$c = "Red"
	}
	elseif($severity -eq "warn")
	{
		$s = "WARNING:"
		$c = "Yellow"
	}
	elseif($severity -eq "pass")
	{
		$s = "OK:     "
		$c = "Green"
	}
	else
	{
		$s = "INFO:   "
		$c = "Gray"
	}

	try
	{
		Out-File -Append -Encoding utf8 -FilePath "c:\scripts\logs\NetBackupTestRestore.log" -InputObject ("{1:yyyy-MM-dd HH:mm:ss}    {2} {0}" -f $message, [DateTime]::Now, $s)
	}
	catch
	{
		Write-Host -ForegroundColor Red $_.Exception.Message
	}
	Write-Host -ForegroundColor $c $message
}

function Invoke-SQL
{
    param(
        [string] $dataSource =  $(throw "Please specify a server."),
        [string] $sqlCommand = $(throw "Please specify a query.")
      )

    $connectionString = "Data Source=$dataSource; " +
            "Integrated Security=SSPI"

    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $command.CommandTimeout = 0
    $connection.Open()

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null

    $connection.Close()
    return $dataSet.Tables
}

function ExecuteNonQueryFailover($cmd)
{
	$retry = 5
	while($retry)
	{
		try
		{
			$cmd.ExecuteNonQuery() | Out-Null
			$retry = 0
		}
		catch
		{
			$retry--
		}
	}
}

trap
{
	Log-Screen -severity 'error' -message ("TRAPPED ERROR: {0}" -f $_)
	continue
}

Log-Screen "info" ("--- " + (Get-Date).ToString("dd/MM/yyyy HH:mm") + " ---")

$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString= "DSN=web.contoso.com;"
$conn.open()
$cmd = new-object System.Data.Odbc.OdbcCommand("", $conn)

# Select images marked for test
# $cmd.CommandText = 'SELECT m.`id`, m.`client_name`, m.`media_list`, m.`client_name`, m.`policy_name`, m.`sched_label`, m.`db`, DATE_FORMAT(FROM_UNIXTIME(m.`backup_time`), "%d.%m.%Y") AS `backup_date`, m.`nbimage`, m.`mdfs`, m.`logs`, m.`stripes`, m.`flags` FROM nbt_images AS m WHERE m.`flags` & 0x01 ORDER BY m.`media_list`, m.`backup_time` DESC'

$today = Get-Date

# Select Full-Week images for last 1 month
if($today.Day -lt 7 -and $today.DayOfWeek -eq 1)
{
	$select_week = 'OR (k.`sched_label` = "Full-Week" AND FROM_UNIXTIME(k.`backup_time`) >= DATE_SUB(NOW(), INTERVAL 1 MONTH) AND k.`flags` = 0)'
}

# Select Full-Month images for last 3 month
if($today.Day -lt 7 -and $today.Month -in (1, 6))
{
	$select_month = 'OR (k.`sched_label` = "Full-Month" AND FROM_UNIXTIME(k.`backup_time`) >= DATE_SUB(NOW(), INTERVAL 3 MONTH) AND k.`flags` = 0)'

	# Select Other images for last 3 month
	#$select_month += ' OR (k.sched_label NOT IN ("Full-Month", "Full-Day", "Full-Week") AND FROM_UNIXTIME(k.backup_time) >= DATE_SUB(NOW(), INTERVAL 3 MONTH))'
}

$cmd.CommandText = @'
SELECT m.`id`, m.`client_name`, m.`media_list`, m.`client_name`, m.`policy_name`, m.`sched_label`, m.`db`, DATE_FORMAT(FROM_UNIXTIME(m.`backup_time`), "%d.%m.%Y") AS `backup_date`, m.`nbimage`, m.`mdfs`, m.`logs`, m.`stripes`, m.`flags`
FROM nbt_images AS m
WHERE m.`id` IN (
SELECT MIN(k.`id`)
FROM nbt_images AS k
WHERE
(k.`sched_label` = "Full-Day" AND FROM_UNIXTIME(k.`backup_time`) >= DATE_SUB(NOW(), INTERVAL 7 DAY) AND k.`flags` = 0)
{0}
{1}
GROUP BY k.`db`, k.`client_name`, k.`policy_name`, k.`sched_label`)
ORDER BY m.`media_list`, m.`backup_time`
'@ -f $select_week, $select_month


$dataTable = New-Object System.Data.DataTable
(New-Object system.Data.odbc.odbcDataAdapter($cmd)).fill($dataTable) | Out-Null

$table = ""
$media_required = @()
foreach($row in $dataTable.Rows)
{
	if($row.media_list.length -gt 0)
	{
		$media_list = $row.media_list -split ","
		foreach($media in $media_list)
		{
			if($media -notin $media_required)
			{
				$media_required += $media
			}
		}
	}
	$table += "<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td></tr>" -f $row.client_name, $row.policy_name, $row.sched_label, $row.db, $row.backup_date, $row.media_list
}

$media_required = $media_required | Sort-Object


$body = $header
$body += "<h1>Запущено тестовое восстановление резервных копий баз данных</h1>"

if($media_required.Count -gt 0)
{
	$body += "<p>Предположительный список кассет, требуемых для загрузки в библиотеку:<br /><br />{0}</p>" -f ($media_required -join "<br />")
}

$body += @'
<h1>Список БД для восстановления</h1>
<table>
	<tr><th>Client</th><th>Policy</th><th>Schedule</th><th>DB</th><th>Backup Date</th><th>Media</th></tr>
	{0}
</table>
'@ -f $table

$body += @'
</body>
</html>
'@

Send-MailMessage -from $smtp_from -to $smtp_to -Encoding UTF8 -subject "Running DB backup tests" -bodyashtml -body $body -smtpServer $smtp_server -Credential $smtp_creds


Log-Screen "info" "--- Start testing procedure ---"

$body = $header

$body += @'
<h1>Результат тестового восстановления резервных копий баз данных</h1>
<table>
<tr><th>Client</th><th>Policy</th><th>Schedule</th><th>DB</th><th>Backup Date</th><th>Media</th><th>Restore Time</th><th>Result</th></tr>
'@

foreach($row in $dataTable.Rows)
{
	$body += '<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td>' -f $row.client_name, $row.policy_name, $row.sched_label, $row.db, $row.backup_date, $row.media_list

	Log-Screen "pass" ("DB: " + $row.db +", Image: " + $row.nbimage)
	Log-Screen "info" ("  Media required: " + $row.media_list)
	Log-Screen "info" ("  MDF: " + $row.mdfs + ", LOGS: " + $row.logs + ", Stripes: " + $row.stripes)

	# mark backup image as "RESTORE IN PROGRESS"
	
	$cmd.CommandText = 'UPDATE nbt_images SET `flags` = (`flags` & ~0x01) | 0x10 WHERE `id` = {0}' -f $row.id
	ExecuteNonQueryFailover -cmd $cmd

	# create move script
	
	$mdfs = $row.mdfs -split ","
	
	$mdf = ''
	$i = 0
	foreach($m_name in $mdfs)
	{
		$mdf += $mdf_template -f $m_name, $i
		$i++
	}

	$logs = $row.logs -split ","
	
	$log = ''
	$i = 0
	foreach($l_name in $logs)
	{
		$log += $log_template -f $l_name, $i
		$i++
	}

	$bch = $bch_template -f $mdf, $log, $row.nbimage, $row.stripes, $row.client_name
	Set-Content -Path "c:\_temp\restore.bch" -Value $bch
	
	Log-Only "info" "  Restoring DB..."
	Write-Host -NoNewline "  Restoring DB..."
	
	$start = Get-Date

	#& 'start /wait C:\Program Files\Veritas\NetBackup\bin\dbbackex.exe' -f c:\_temp\restore.bch -u sa -pw B2FSQkvYrPuVeZdj -np
	$proc = Start-Process -FilePath 'C:\Program Files\Veritas\NetBackup\bin\dbbackex.exe' -ArgumentList '-f c:\_temp\restore.bch -u sa -pw B2FSQkvYrPuVeZdj -np' -PassThru
	Wait-Process -InputObject $proc #-Timeout 99999
	$stop = Get-Date
	$duration = (New-TimeSpan –Start $start –End $stop)
	$body += '<td>{0:d2}:{1:d2}</td>' -f [int] ($duration.TotalMinutes / 60), [int] ($duration.TotalMinutes % 60)
	Log-Only "info" ("  Exit code = " + $proc.ExitCode)
	Write-Host -ForegroundColor Green (" result: " + $proc.ExitCode)
	if($proc.HasExited -and $proc.ExitCode -eq 0)
	{
		$dbsize = 0
		try
		{
			$result = Invoke-SQL -dataSource $server -sqlCommand "SELECT SUM(size) * 8. * 1024 AS bytes FROM sys.master_files WHERE DB_NAME(database_id) = 'NB_Test_Restore'"
			$dbsize = $result[0].bytes
		}
		catch
		{
		}

		$cmd.CommandText = 'UPDATE nbt_images SET `restore_date` = NOW(), `duration` = {1}, `dbsize` = {2}, `flags` = 0x40 WHERE id = {0}' -f $row.id, $duration.TotalMinutes, $dbsize
		ExecuteNonQueryFailover -cmd $cmd

		Log-Only "info" "  Checking DB..."
		Write-Host -NoNewline "  Checking DB..."

		$status = 0
		
		if($row.db -ne 'master')
		{
			try
			{
				$result = Invoke-SQL -dataSource "srv-nbtest-01" -sqlCommand "DBCC CHECKDB ([NB_Test_Restore]) WITH TABLERESULTS"
				foreach($r in $result)
				{
					if($r.Status -ne 0)
					{
						$status = 1
					}
				}
			}
			catch
			{
				$status = 1
				Log-Only "error" ("  Exception: " + $_.Exception.Message)
				Write-Host -NoNewline -ForegroundColor Red (" (" + $_.Exception.Message + ")")
			}
		}

		if($status -eq 0)
		{
			$cmd.CommandText = 'UPDATE nbt_images SET `restore_date` = NOW(), `duration` = {1}, `dbsize` = {2}, `flags` = 0x02 WHERE id = {0}' -f $row.id, $duration.TotalMinutes, $dbsize
			ExecuteNonQueryFailover -cmd $cmd
			$body += '<td class="pass">PASSED</td></tr>'
			Log-Only "info" "  Check DB - OK"
			Write-Host -ForegroundColor Green (" OK")
		}
		else
		{
			$cmd.CommandText = 'UPDATE nbt_images SET `restore_date` = NOW(), `duration` = {1}, `dbsize` = {2}, `flags` = 0x04 WHERE id = {0}' -f $row.id, $duration.TotalMinutes, $dbsize
			ExecuteNonQueryFailover -cmd $cmd
			$body += '<td class="error">CHECKDB FAILED</td></tr>'
			Log-Only "info" "  Check DB - FAILED"
			Write-Host -ForegroundColor Red (" FAILED")
		}
	}
	else
	{
		$cmd.CommandText = 'UPDATE nbt_images SET `restore_date` = NOW(), `duration` = {1}, `dbsize` = 0, `flags` = 0x08 WHERE id = {0}' -f $row.id, $duration.TotalMinutes
		ExecuteNonQueryFailover -cmd $cmd
		$body += '<td class="error">RESTORE FAILED</td></tr>'
	}

	Log-Screen "info" "  Deleting DB..."

	try
	{
		$result = Invoke-SQL -dataSource "srv-nbtest-01" -sqlCommand "USE master`r`nIF EXISTS(select * from sys.databases where name='NB_Test_Restore')`r`nDROP DATABASE NB_Test_Restore"
	}
	catch
	{
		Log-Screen "error" "Error drop test DB"
		$body += '<tr><td colspan=8 class="error">Error drop test DB</td></tr>'
	}
}

Log-Screen "info" ("--- Done --- " + (Get-Date).ToString("dd/MM/yyyy HH:mm") + " ---")

$body += @'
</table>
</body>
</html>
'@

Send-MailMessage -from $smtp_from -to $smtp_to -Encoding UTF8 -subject "Result DB backup tests" -bodyashtml -body $body -smtpServer $smtp_server -Credential $smtp_creds
