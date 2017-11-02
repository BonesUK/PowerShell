$success = 0
$PercentComplete = 0

Do 
{
    $evt = Get-EventLog "DFS Replication" | ? { $_.EventID -eq 2416 } | Select-Object -first 1

    if ($evt) 
    {
        $trim1 = ($evt.message.split("") | select-string "processed:" ).ToString() -match "(\d+)"
        [int32]$processed=$matches[1]

        $trim2 = ($evt.message.split("") | select-string "Remaining:" ).ToString() -match "(\d+)"
        [int32]$remaining=$matches[1]

        $StartingValue = $processed + $remaining
                   
        [INT]$PercentComplete = ($processed / $StartingValue) * 100

        Write-Output "DFSR DB import process is $PercentComplete`% complete. $processed of $StartingValue records processed "

        Start-sleep -Seconds 60
    }
    else 
    {
        Write-Host "Event 2410 not found - waiting for import to commence"
        Start-Sleep -seconds 60
    }
}

until ($PercentComplete -ge 100)

Write-Output "DFSR DB import process is $PercentComplete`% complete. Use robocopy to copy DFSR database file over to target server."