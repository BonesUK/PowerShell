<# 
        DFSR Monitoring Tool
        Written by Tony Roud

        The DfsrHealthCheck module is required for the monitoring script to work
#>

#   Import the module before going any further
Import-Module "C:\Program Files\WindowsPowerShell\Modules\DFSHealthCheck\DfsrHealthCheck.psm1"

<# 
Basic configuration settings

Configure the replicated folders you wish to monitor by storing them in the $replicatedFolder variable

You can enter these manually for example: $replicatedFolder = "Folder1","Folder2","Folder3"
Alternatively you can pull the content from a text file: $replicatedFolder = Get-Content "Folders.txt"
#>
$replicatedFolder = Get-Content "C:\Program Files\WindowsPowerShell\Modules\DFSHealthCheck\ReplicatedFolders.txt"

# Specify the location of the output file for the script
# This effectively caches the output and prevents Check_MK raising alerts if the script takes too long to return a result
$outputfile = "C:\Program Files\WindowsPowerShell\Modules\DFSHealthCheck\Outputfile.txt"

# Configure the warning and critical thresholds for dfsr backlogs
$WarnThreshold = 100
$CritThreshold = 1000

# Add a timestamp to output file
$timestamp = Get-Date -f "dd/MM/yyyy HH:mm:ss"
Write-Verbose "Last DFSRHealthCheck monitor run: $timestamp"
$output = "# Last DFSRHealthCheck monitor run: $timestamp;"

Write-Verbose "Checking status of DFSR service"
$dfsrServiceStatus = Get-DfsrServiceStatus
$output += "$($dfsrServiceStatus.status) DFSRServiceStatus - $($dfsrServiceStatus.message)" + ";"

Write-Verbose "Checking status of WinRM service"
$winrmServiceStatus = Get-WinRMServiceStatus
$output += "$($winrmServiceStatus.status) WinRMServiceStatus - $($winrmServiceStatus.message)" + ";"

# Check for DFSR Critical events
Write-Verbose "Checking for critical events in DFSR log in the last 60 mins"
$dfsrEvents = Get-DfsrCriticalEvents
$output += "$($dfsrEvents.status) DFSRReplicationEvents - $($dfsrEvents.message)" + ";"

# Now call execute the main monitoring function against each folder in $replicatedfolder and capture all output to a variable
# This prevents the file being written to until all the output is ready
Foreach ($folder in $replicatedFolder) 
{
    $replicatedfolderstatus = Get-DfsrHealthCheckStatus -replicatedfolder $folder -WarnThreshold $warnThreshold -CritThreshold $critthreshold -Verbose
    $output += "[$folder]" + $replicatedfolderstatus + ";"
}

# Create the output file (overwrite the previous file) 
$outputfilepath = New-Item -Path $outputfile -ItemType File -Force

# Now push the output to file so the Check_MK script can parse it
$output.Split(";") | Out-File -FilePath $outputfile -append