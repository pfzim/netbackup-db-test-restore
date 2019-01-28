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
        #$date = (((Get-Date "1970-01-01 00:00:00.000Z") + ([TimeSpan]::FromSeconds($j.backup_time)))).ToString("MM/dd/yyyy HH:mm")
        #$images = (& 'C:\Program Files\Veritas\NetBackup\bin\bplist.exe' -s $date -e $date -C $j.client_name -k $j.policy_name -t 15 -R \) | Sort-Object -Unique
        $image_data = (& 'C:\Program Files\Veritas\NetBackup\bin\admincmd\bpflist.exe' -rl 1 -backupid $j.backupid -json)
        $image = $image_data | ConvertFrom-Json
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
	
	foreach($f in $image.fentries)
	{
		$data = $f.path.Substring(1, $f.path.Length - 1) -split '\.'

		if($data[3] -eq 'db' -and ($data[7].Substring(0, 5) -eq '001of'))
		{
			if(!$data_found -and $f.data -match "MSSQL_METADATA_FILES\s+([^\s]+)$")
			{
				$data_found = $true
				$mdf = $matches[1]
                $date = $data[8]
                $db = $data[4]
				$stripes = [int] $data[7].Substring(5, 3)
				$nbimage = $f.path.Substring(1, $f.path.Length - 1)
			}
			elseif($f.data -match "MSSQL_METADATA_LOGFILE\s+([^\s]+)$")
			{
				$logs += $matches[1]
			}
        }
    }
	
	if($data_found)
	{
		try
		{
			$cmd.CommandText = 'SELECT COUNT(*) FROM nbt_images AS m WHERE m.`backupid` = "{0}" OR m.`nbimage` = "{1}"' -f $j.backupid, $nbimage
			$exist = [int] $cmd.ExecuteScalar()
			if($exist -eq 0)
			{
				$cmd.CommandText = 'INSERT INTO nbt_images (`policy_name`, `sched_label`, `client_name`, `backup_time`, `expiration`, `backupid`, `ss_name`, `media_list`, `nbimage`, `date2`, `db`, `stripes`, `mdf`, `logs`) VALUES ("{0}", "{1}", "{2}", "{3}", "{4}", "{5}", "{6}", "{7}", "{8}", "{9}", "{10}", "{11}", "{12}", "{13}")' -f $j.policy_name, $j.sched_label, $j.client_name, $j.backup_time, $j.expiration, $j.backupid, $j.ss_name, ($media_list -join ","), $nbimage, $date, $db, $stripes, $mdf, ($logs -join ",")
				$cmd.CommandText
				#$cmd = new-object System.Data.Odbc.OdbcCommand($query,$conn)
				$cmd.ExecuteNonQuery() | Out-Null
			}
			else
			{
				Write-Host -ForegroundColor Red ("SKIPPED existing backup {1} : {0}" -f $nbimage, $j.backupid)
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
