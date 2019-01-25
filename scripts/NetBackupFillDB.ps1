Clear-Host

$sd = (Get-Date).AddDays(-365).ToString("MM/dd/yyyy HH:mm")
$ed = (Get-Date).ToString("MM/dd/yyyy HH:mm")

#& 'C:\Program Files\Veritas\NetBackup\bin\admincmd\bpimagelist.exe' -d $sd -e $ed -json -json_array  -client brc-scom-01 -policy SQL_BusinessDB_Gold -st Full  #-json -json_array

$data = & 'C:\Program Files\Veritas\NetBackup\bin\admincmd\bpimagelist.exe' -d $sd -e $ed -json -json_array -pt MS-SQL-Server -st Full
$json = $data | ConvertFrom-Json

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
        $cmd.CommandText = 'SELECT COUNT(*) FROM nbt_images AS m WHERE m.`backupid` = "{0}"' -f $j.backupid
        $last_id = [int] $cmd.ExecuteScalar()
        if($last_id -eq 0)
        {
            $cmd.CommandText = 'INSERT INTO nbt_images (`policy_name`, `sched_label`, `client_name`, `backup_time`, `expiration`, `backupid`, `ss_name`, `media_list`) VALUES ("{0}", "{1}", "{2}", "{3}", "{4}", "{5}", "{6}", "{7}")' -f $j.policy_name, $j.sched_label, $j.client_name, $j.backup_time, $j.expiration, $j.backupid, $j.ss_name, ($media_list -join ",")
            $cmd.CommandText
            $cmd.ExecuteNonQuery() | Out-Null
            $cmd.CommandText = "SELECT LAST_INSERT_ID()"
            $last_id = [int] $cmd.ExecuteScalar()
        }
    }
    catch
    {
        Write-Host -ForegroundColor Red $_.Exception.Message
    }

    $date = (((Get-Date "1970-01-01 00:00:00.000Z") + ([TimeSpan]::FromSeconds($j.backup_time)))).ToString("MM/dd/yyyy HH:mm")

    try
    {
        #$images = (& 'C:\Program Files\Veritas\NetBackup\bin\bplist.exe' -s $date -e $date -C $j.client_name -k $j.policy_name -t 15 -R \) | Sort-Object -Unique
        $image_data = (& 'C:\Program Files\Veritas\NetBackup\bin\admincmd\bpflist.exe' -rl 1 -backupid $j.backupid -json)
        $image = $image_data | ConvertFrom-Json
    }
    catch
    {
        continue
    }

	foreach($f in $image.fentries)
	{
		$data = $f.path.Substring(1, $f.path.Length - 1) -split '\.'

		if($data[3] -eq 'db' -and ($data[7].Substring(0, 5) -eq '001of'))
		{
		    $stripes = [int] $data[7].Substring(5, 3)
		    $nbimage = $f.path.Substring(1, $f.path.Length - 1)

            try
            {
                $cmd.CommandText = 'SELECT COUNT(*) FROM nbt_files AS m WHERE m.`name` = "{0}"' -f $nbimage
                $exist = [int] $cmd.ExecuteScalar()
                if($exist -eq 0)
                {
                    $cmd.CommandText = 'INSERT INTO nbt_files (`pid`, `name`, `date2`, `db`, `stripes`) VALUES ("{0}", "{1}", "{2}", "{3}", "{4}")' -f $last_id, $nbimage, $data[8], $data[4], $stripes
                    $cmd.CommandText
                    #$cmd = new-object System.Data.Odbc.OdbcCommand($query,$conn)
                    $cmd.ExecuteNonQuery() | Out-Null
                    break
                }
                else
                {
                    Write-Host -ForegroundColor Red ("ERROR Exist {1} : {0}" -f $nbimage, $j.backupid)
                }
            }
            catch
            {
                Write-Host -ForegroundColor Red $_.Exception.Message
            }
        }
    }
    <##>
}
$conn.close()


# UPDATE nbt_files SET `date` = CONCAT(SUBSTRING(`date2`, 1, 4), '-', SUBSTRING(`date2`, 5, 2), '-', SUBSTRING(`date2`, 7, 2), ' ', SUBSTRING(`date2`, 9, 2), ':', SUBSTRING(`date2`, 11, 2), ':', SUBSTRING(`date2`, 13, 2));
