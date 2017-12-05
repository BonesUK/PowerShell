<# 
    Check_MK Local DFSR Monitoring script
    This script parses the output from the full monitoring script at "C:\Program Files\WindowsPowerShell\Modules\DFSHealthCheck\DfsrHealthCheck.ps1"
    Any configuration changes need to be made in the above script.

    The DfsrHealthCheck script is being run every 5 mins from task scheduler and the output saved to the below 'outputfile' location

    Requires the DFSRHealthCheck module to run successfully.

#>

# Location of output file
$outputfile = 'C:\Program Files\WindowsPowerShell\Modules\DFSRHealthCheck\Outputfile.csv'

# Pull in the content from output file
$output = Import-Csv $outputfile

# Check the last run time and make sure it hasn't been more than 15 mins or data could be stale.
$start = get-date ((get-content $outputfile | Select-String -Pattern "#").ToString().Substring(2))
$end = (get-date)

if ((New-TimeSpan -Start $start -End $end).Minutes -ge 16) 
{
    Write-Output '1 DFSRMonitorLastRun - Warning: DFSR Monitor script has not run for 15 mins. Check the script is running in task scheduler.'

    Foreach ($monitor in $output)
    {
        Write-Output "1 $($monitor.checkname) - No output available. Manually check DFSR health on server."
    }
}

else
{
    Write-Output "0 DFSRMonitorLastRun - DFSR Monitor script ran successfully at $start."
    
    Foreach ($monitor in $output)
    {
        Write-Output "$($monitor.status) $($monitor.checkname) - $($monitor.output)"
    }
}