$ErrorActionPreference = "Stop"

Clear-Host

$sd = (Get-Date).AddDays(-365).ToString("MM/dd/yyyy HH:mm")
$ed = (Get-Date).ToString("MM/dd/yyyy HH:mm")

#& 'C:\Program Files\Veritas\NetBackup\bin\admincmd\bpimagelist.exe' -d $sd -e $ed -json -json_array  -client brc-scom-01 -policy SQL_BusinessDB_Gold -st Full  #-json -json_array

#<#
$data = & 'C:\Program Files\Veritas\NetBackup\bin\admincmd\bpimagelist.exe' -d $sd -e $ed -json -json_array -pt MS-SQL-Server -st Full
$json = $data | ConvertFrom-Json
<##>

$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString= "DSN=web.bristolcapital.ru;"
$conn.open()
$cmd = new-object System.Data.Odbc.OdbcCommand("", $conn)

$cmd.CommandText = 'UPDATE nbt_images SET `flags` = `flags` | 0x20'
$cmd.CommandText
$cmd.ExecuteNonQuery() | Out-Null

$last_id = 0

foreach($j in $json)
{
	$media_list = @()

    foreach($f in $j.frags)
    {
        if($f.media_type -eq 2 -and $f.id -notin $media_list)
        {
			$media_list += $f.id
        }
    }
    
    $media_list = $media_list | Sort-Object


    try
    {
		<# json version
        $image_data = (& 'C:\Program Files\Veritas\NetBackup\bin\admincmd\bpflist.exe' -rl 1 -backupid $j.backupid -json)
        $image = $image_data | ConvertFrom-Json
		<##>
		
        $images = (& 'C:\Program Files\Veritas\NetBackup\bin\admincmd\bpflist.exe' -rl 1 -backupid $j.backupid)
    }
    catch
    {
        continue
    }
	
	$logs = @()
	$mdf = ""
    $nbimage = ""
    $date = ""
    $db = ""
	$stripes = 0
	$data_found = $false
	$mdf_found = $false
	$log_found = $false
	
	<# json version
	foreach($f in $image.fentries)
	{
		$data = $f.path.Substring(1, $f.path.Length - 1) -split '\.'

		if($data[3] -eq 'db' -and ($data[7].Substring(0, 5) -eq '001of'))
		{
			if(!$data_found)
			{
				$data_found = $true
                $date = $data[8]
                $db = $data[4]
				$stripes = [int] $data[7].Substring(5, 3)
				$nbimage = $f.path.Substring(1, $f.path.Length - 1)
			}
			
			if($f.data -match "MSSQL_METADATA_FILES\s+([^\s].*)$")
			{
				$mdf = $matches[1]
				$mdf_found = $true
			}
			elseif($f.data -match "MSSQL_METADATA_LOGFILE\s+([^\s].*)$")
			{
				$logs += $matches[1]
				$log_found = $true
			}
        }
    }
	<##>
	
    #<# plain text
	foreach($image in $images)
	{
		
		if($image -match "\s/(.+\.\.C)\s")
		{
			$path = $matches[1]
			$data = $path.Substring(1, $path.Length - 1) -split '\.'

			if($data[3] -eq 'db' -and ($data[7].Substring(0, 5) -eq '001of'))
			{
				if(!$data_found)
				{
					$data_found = $true
					$date = $data[8]
					$db = $data[4]
					$stripes = [int] $data[7].Substring(5, 3)
					$nbimage = $path
				}
				
				if($image -match "MSSQL_METADATA_FILES\s+([^\s].*)$")
				{
					$mdf = $matches[1]
					$mdf_found = $true
				}
				elseif($image -match "MSSQL_METADATA_LOGFILE\s+([^\s].*)$")
				{
					$logs += $matches[1]
					$log_found = $true
				}
			}
		}
    }
    <##>

	if($data_found)
	{
		try
		{
			$cmd.CommandText = 'SELECT COUNT(*) FROM nbt_images AS m WHERE m.`backupid` = "{0}"' -f $j.backupid
			$exist = [int] $cmd.ExecuteScalar()
			if($exist -eq 0)
			{
				$cmd.CommandText = 'INSERT INTO nbt_images (`policy_name`, `sched_label`, `client_name`, `backup_time`, `expiration`, `backupid`, `ss_name`, `media_list`, `nbimage`, `date2`, `db`, `stripes`, `mdf`, `logs`) VALUES ("{0}", "{1}", "{2}", "{3}", "{4}", "{5}", "{6}", "{7}", "{8}", "{9}", "{10}", "{11}", "{12}", "{13}")' -f $j.policy_name, $j.sched_label, $j.client_name, $j.backup_time, $j.expiration, $j.backupid, $j.ss_name, ($media_list -join ","), $nbimage, $date, $db, $stripes, $mdf, ($logs -join ",")
			}
			else
			{
				$cmd.CommandText = 'UPDATE nbt_images SET `policy_name` = "{0}", `sched_label` = "{1}", `client_name` = "{2}", `backup_time` = "{3}", `expiration` = "{4}", `ss_name` = "{5}", `media_list` = "{6}", `nbimage` = "{7}", `date2` = "{8}", `db` = "{9}", `stripes` = "{10}", `mdf` = "{11}", `logs` = "{12}", `flags` = `flags` & ~0x20 WHERE `backupid` = "{13}"' -f $j.policy_name, $j.sched_label, $j.client_name, $j.backup_time, $j.expiration, $j.ss_name, ($media_list -join ","), $nbimage, $date, $db, $stripes, $mdf, ($logs -join ","), $j.backupid
			}
			
			$cmd.CommandText
			#$cmd = new-object System.Data.Odbc.OdbcCommand($query,$conn)
			$cmd.ExecuteNonQuery() | Out-Null

			if(!$mdf_found)
			{
				Write-Host -ForegroundColor Yellow ("  WARNING no mdf name found for ID: {0}" -f $j.backupid)
			}

			if(!$log_found)
			{
				Write-Host -ForegroundColor Yellow ("  WARNING no log name found for ID: {0}" -f $j.backupid)
			}
		}
		catch
		{
			Write-Host -ForegroundColor Red $_.Exception.Message
		}
	}
	else
	{
		Write-Host -ForegroundColor Red ("SKIPPED no data found for ID: {0}" -f $j.backupid)
	}
    <##>
}
$conn.close()



# UPDATE nbt_files SET `date2` = CONCAT(SUBSTRING(`date`, 1, 4), '-', SUBSTRING(`date`, 5, 2), '-', SUBSTRING(`date`, 7, 2), ' ', SUBSTRING(`date`, 9, 2), ':', SUBSTRING(`date`, 11, 2), ':', SUBSTRING(`date`, 13, 2));
