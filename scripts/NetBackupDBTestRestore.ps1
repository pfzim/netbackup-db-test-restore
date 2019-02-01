# Run restore test for marked images

# Flags
# 0x01 = WAIT FOR TEST
# 0x02 = TESTED OK
# 0x04 = FAILED CHECKDB
# 0x08 = FAILED RESTORE
# 0x10 = TESTING IN PROGRESS
# 0x20 = NOT FOUND

$ErrorActionPreference = "Stop"

$smtp_from = "orchestrator@bristolcapital.ru"
$smtp_to = "admin@bristolcapital.ru"
$smtp_server = "smtp.bristolcapital.ru"

$smtp_creds = New-Object System.Management.Automation.PSCredential ("", (ConvertTo-SecureString "" -AsPlainText -Force))


$log_template = @'
MOVE  "{0}"
TO  "F:\Workdata\NB_Test_Restore_log_{1}.ldf"

'@

$bch_template = @'
OPERATION RESTORE
OBJECTTYPE DATABASE
RESTORETYPE MOVE
DATABASE "NB_Test_Restore"
MOVE  "{0}"
TO  "F:\Workdata\NB_Test_Restore.mdf"
{1}
NBIMAGE "{2}"
SQLHOST "BRC-NBTEST-01"
SQLINSTANCE "MSSQLSERVER"
NBSERVER "BRC-NB-01.BRISTOLCAPITAL.RU"
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
    $command.CommandTimeout = 86400
    $connection.Open()

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null

    $connection.Close()
    return $dataSet.Tables
}


Log-Screen "info" ("--- " + (Get-Date).ToString("dd/MM/yyyy HH:mm") + " ---")

$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString= "DSN=web.bristolcapital.ru;"
$conn.open()
$cmd = new-object System.Data.Odbc.OdbcCommand("", $conn)

$cmd.CommandText = 'SELECT m.`id`, m.`client_name`, m.`media_list`, m.`client_name`, m.`policy_name`, m.`sched_label`, m.`db`, DATE_FORMAT(FROM_UNIXTIME(m.`backup_time`), "%d.%m.%Y") AS `backup_date`, m.`nbimage`, m.`mdf`, m.`logs`, m.`stripes`, m.`flags` FROM nbt_images AS m WHERE m.`flags` & 0x01 ORDER BY m.`media_list`, m.`backup_time` DESC'

$dataTable = New-Object System.Data.DataTable
(New-Object system.Data.odbc.odbcDataAdapter($cmd)).fill($dataTable) | Out-Null

$table = ""
$media_required = @()
foreach($row in $dataTable.Rows)
{
    $media_list = $row.media_list -split ","
    foreach($media in $media_list)
    {
        if($media -notin $media_required)
        {
            $media_required += $media
        }
    }
	$table += "<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td></tr>" -f $row.client_name, $row.policy_name, $row.sched_label, $row.db, $row.backup_date
}

$media_required | Sort-Object


$body = $header
$body += @'
<h1>Запущено тестовое восстановление резервных копий баз данных</h1>
<p>Предположительный список кассет, требуемых для загрузки в библиотеку:
<br /><br />{0}
</p>
<h1>Список БД для восстановления</h1>
<table>
	<tr><th>Client</th><th>Policy</th><th>Schedule</th><th>DB</th><th>Backup Date</th></tr>
	{1}
</table>
'@ -f ($media_required -join "<br />"), $table

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
<tr><th>Client</th><th>Policy</th><th>Schedule</th><th>DB</th><th>Backup Date</th><th>Restore Time</th><th>Result</th></tr>
'@

foreach($row in $dataTable.Rows)
{
	$body += '<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td>' -f $row.client_name, $row.policy_name, $row.sched_label, $row.db, $row.backup_date

	Log-Screen "pass" ("DB: " + $row.db +", Image: " + $row.nbimage)
	Log-Screen "info" ("  Media required: " + $row.media_list)
	Log-Screen "info" ("  MDF: " + $row.mdf + ", LOGS: " + $row.logs + ", Stripes: " + $row.stripes)

	$cmd.CommandText = 'UPDATE nbt_images SET `flags` = (`flags` & ~0x01) | 0x10 WHERE id = {0}' -f $row.id
	$cmd.ExecuteNonQuery() | Out-Null

	# create move script
	
	$logs = $row.logs -split ","
	
	$log = ''
	$i = 0
	foreach($l_name in $logs)
	{
		$log += $log_template -f $l_name, $i
		$i++
	}

	$bch = $bch_template -f $row.mdf, $log, $row.nbimage, $row.stripes, $row.client_name
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
			$result = Invoke-SQL -dataSource $server -sqlCommand "SELECT SUM(size) * 8. AS bytes FROM sys.master_files WHERE DB_NAME(database_id) = 'NB_Test_Restore'"
			$dbsize = $result[0].bytes
		}
		catch
		{
		}

		Log-Only "info" "  Checking DB..."
		Write-Host -NoNewline "  Checking DB..."

		$status = 0
		try
		{
			$result = Invoke-SQL -dataSource "brc-nbtest-01" -sqlCommand "DBCC CHECKDB ([NB_Test_Restore]) WITH TABLERESULTS"
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

		if($status -eq 0)
		{
			$cmd.CommandText = 'UPDATE nbt_images SET `restore_date` = NOW(), `duration` = {1}, `dbsize` = {2}, `flags` = 0x02 WHERE id = {0}' -f $row.id, $duration.TotalMinutes, $dbsize
			$cmd.ExecuteNonQuery() | Out-Null
			$body += '<td class="pass">PASSED</td></tr>'
			Log-Only "info" "  Check DB - OK"
			Write-Host -ForegroundColor Green (" OK")
		}
		else
		{
			$cmd.CommandText = 'UPDATE nbt_images SET `restore_date` = NOW(), `duration` = {1}, `dbsize` = {2}, `flags` = 0x04 WHERE id = {0}' -f $row.id, $duration.TotalMinutes, $dbsize
			$cmd.ExecuteNonQuery() | Out-Null
			$body += '<td class="error">CHECKDB FAILED</td></tr>'
			Log-Only "info" "  Check DB - FAILED"
			Write-Host -ForegroundColor Red (" FAILED")
		}
	}
	else
	{
		$cmd.CommandText = 'UPDATE nbt_images SET `restore_date` = NOW(), `duration` = {1}, `dbsize` = 0, `flags` = 0x08 WHERE id = {0}' -f $row.id, $duration.TotalMinutes
		$cmd.ExecuteNonQuery() | Out-Null
		$body += '<td class="error">RESTORE FAILED</td></tr>'
	}

	Log-Screen "info" "  Deleting DB..."

	try
	{
		$result = Invoke-SQL -dataSource "brc-nbtest-01" -sqlCommand "USE master`r`nIF EXISTS(select * from sys.databases where name='NB_Test_Restore')`r`nDROP DATABASE NB_Test_Restore"
	}
	catch
	{
		Log-Screen "error" "Error drop test DB"
		$body += '<tr><td class="error">Error drop test DB</td></tr>'
	}
}

Log-Screen "info" ("--- Done --- " + (Get-Date).ToString("dd/MM/yyyy HH:mm") + " ---")

$body += @'
</table>
</body>
</html>
'@

Send-MailMessage -from $smtp_from -to $smtp_to -Encoding UTF8 -subject "Result DB backup tests" -bodyashtml -body $body -smtpServer $smtp_server -Credential $smtp_creds
