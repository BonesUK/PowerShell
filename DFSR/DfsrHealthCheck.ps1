<# 
    DFSR Monitoring Script
    Requires DfsrHealthCheck module for script to work.
#>

#   Import the module before going any further
Import-Module 'C:\Program Files\WindowsPowerShell\Modules\DFSRHealthCheck\DfsrHealthCheck.psm1'

<# 
Basic configuration settings

Pull in the replicated folder info from WMI and store in the $replicatedFolder variable
Alternatively you can enter these manually for example: $replicatedFolder = "Folder1","Folder2","Folder3"
You can also pull the content from a text file: $replicatedFolder = Get-Content "Folders.txt"
#>
$replicatedFolders = Get-WmiObject -Namespace "root\Microsoft\Windows\DFSR" -Class msft_dfsrreplicatedfolderinfo | Select-Object replicatedfoldername

# Specify the location of the output file for the script
# This effectively caches the output and prevents Check_MK raising alerts if the script takes too long to return a result
$outputfile = 'C:\Program Files\WindowsPowerShell\Modules\DFSRHealthCheck\Outputfile.csv'

# Configure the warning and critical thresholds for dfsr backlogs
$WarnThreshold = 100
$CritThreshold = 1000

# Create a timestamp and add to output so monitoring script knows data is fresh 
$timestamp = Get-Date -f 'dd/MM/yyyy HH:mm:ss'
[String[]]$output = "# $timestamp"
$output += "Status,CheckName,Output,"

# Check DFSR & WinRM Services are running
$dfsrServiceStatus = Get-DfsrServiceStatus -Verbose
$output += $($dfsrServiceStatus.status) + ',' + 'DFSRServiceStatus' + ',' + $($dfsrServiceStatus.message) + ','

$winrmServiceStatus = Get-WinRMServiceStatus -Verbose
$output += $($winrmServiceStatus.status) + ',' + 'WinRmServiceStatus' + ',' + $($winrmServiceStatus.message) + ','

# Check for DFSR Critical events. Set the treshold parameter in hours.
$dfsrEvents = Get-DfsrCriticalEvents -threshold 1 -Verbose
$output += $($dfsrEvents.status) + ',' + 'DFSREvents' + ',' + $($dfsrEvents.message) + ','

# Check replicated folder status
$ReplicatedFolderState = Get-ReplicatedFolderState -Verbose
$output += $($ReplicatedFolderState.status) + ',' + 'DFSReplicatedFolderStatus' + ',' + $($ReplicatedFolderState.message) + ','

# Now call execute the main monitoring function against each folder in $replicatedfolder and capture all output to a variable
# This prevents the file being written to until all the output is ready
Foreach ($replicatedFolder in $replicatedFolders) 
{
    $folder = $replicatedFolder.replicatedfoldername
    $replicatedfolderstatus = Get-DfsrHealthCheck -folder $folder -WarnThreshold $warnThreshold -CritThreshold $critthreshold -Verbose
    $output += $($replicatedfolderstatus.status) + ',' + $($replicatedfolderstatus.checkname) + ',' + $($replicatedfolderstatus.message) + ','
}

# Create the output file (overwrite the previous file) 
New-Item -Path $outputfile -ItemType File -Force

# Now push the output to file so the Check_MK script can parse it
$output | Out-File -FilePath $outputfile