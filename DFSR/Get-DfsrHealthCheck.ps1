# Basic configuration settings
# Configure the replicated folders you wish to monitor
$replicatedFolder = "Folder1","Folder2","Folder3"

# Configure the warning and critical thresholds for dfsr backlogs
$WarnThreshold = 100
$CritThreshold = 1000

# DFSR and WinRM service checks
$dfsrServiceStatus = Get-DfsrServiceStatus
Write-Output "$($dfsrServiceStatus.status) DFSRServiceStatus - $($dfsrServiceStatus.message)"

$winrmServiceStatus = Get-WinRMServiceStatus
Write-Output "$($winrmServiceStatus.status) DFSRServiceStatus - $($winrmServiceStatus.message)"

# Perform healthcheck on replicated folders
Test-DfsrReplicationHealth -replicatedfolder $replicatedFolder -WarnThreshold $warnThreshold -CritThreshold $critthreshold

# Check for DFSR Critical events
$dfsrEvents = Get-DfsrCriticalEvents
Write-Output "$($dfsrEvents.status) DFSRReplicationEvents - $($dfsrEvents.message)"

