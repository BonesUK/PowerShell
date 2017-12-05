<# 
    DFSR Monitoring Script
    Requires DfsrHealthCheck module for script to work.
#>

#   Import the module before going any further
Import-Module 'C:\Program Files\WindowsPowerShell\Modules\DFSRHealthcheck\DFSRHealthcheck.psm1' -verbose

<# 
Basic configuration settings

Pull in the replicated folder info from WMI and store in the $replicatedFolder variable
Alternatively you can enter these manually for example: $replicatedFolder = "Folder1","Folder2","Folder3"
You can also pull the content from a text file: $replicatedFolder = Get-Content "Folders.txt"
#>
$replicatedFolders = "Depts","FootDev","HomeDirs"

# Configure the warning and critical thresholds for dfsr backlogs
$WarnThreshold = 100
$CritThreshold = 1000

# Check DFSR & WinRM Services are running
$dfsrServiceStatus = Get-DfsrServiceStatus -Verbose
Write-Output "$($dfsrServiceStatus.status) DFSRServiceStatus - $($dfsrServiceStatus.message)"

$winrmServiceStatus = Get-WinRMServiceStatus -Verbose
Write-Output "$($winrmServiceStatus.status) WinRmServiceStatus - $($winrmServiceStatus.message)"

# Check for DFSR Critical events. Set the treshold parameter in hours.
$dfsrEvents = Get-DfsrCriticalEvents -threshold 1 -Verbose
Write-Output "$($dfsrEvents.status) DFSREvents - $($dfsrEvents.message)"

# Check replicated folder status
$ReplicatedFolderState = Get-ReplicatedFolderState -Verbose
Write-Output "$($ReplicatedFolderState.status) DFSReplicatedFolderStatus - $($ReplicatedFolderState.message)"

# Now call execute the main monitoring function against each folder in $replicatedfolder
Foreach ($replicatedFolder in $replicatedFolders) 
{
    $replicatedfolderstatus = Get-DfsrHealthCheck -folder $replicatedFolder -WarnThreshold $warnThreshold -CritThreshold $critthreshold -Verbose
    Write-Output "$($replicatedfolderstatus.status) $($replicatedfolderstatus.checkname) - $($replicatedfolderstatus.message)"
}