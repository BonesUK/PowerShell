<#
To Do:
Add error handling for 
#>

# Region monitoring functions
# Get a count of replication groups and replicated folders
function Get-DfsrFolderInformation {
    [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]$replicatedFolder
        )

    $connectionWarning = $false
    $dfsrFolderInfo = Get-DfsReplicatedFolder -FolderName $replicatedFolder
    
    try 
    {
        $dfsrConnections = Get-DfsrConnection -GroupName $($dfsrFolderInfo.Groupname) | Where-Object { $_.SourceComputerName -eq $env:COMPUTERNAME }
    }
    catch 
    {
        $connectionWarning = $true  
    }

    $props = @{ 'DfsrGroup' = $dfsrFolderInfo.Groupname;
                'ReplicatedFolder' = $replicatedFolder;
                'DfsrSourceComputer' = $dfsrConnections.SourceComputerName;
                'DfsrDestinationComputer' = $dfsrConnections.DestinationComputerName;
                'ConnectionWarning' = $connectionWarning
    }

    New-Object -Typename PSObject -Property $props
}

# Check for critical replication events in DFSR log (replication stopped on folder)
function Get-DfsrCriticalEvents {

    $status = 0
    $message = "No critical events found in DFSR log"

    $event = Get-WinEvent -LogName "DFS Replication" | Where-Object { $_.message -match "DFS Replication service stopped replication on the replicated folder" }
    if ($event)
    {
        $status = 2
        $message = "Warning - Critical DFSR replication events found. Replication may have stopped for one or more replicated folders"
    }

    $props = @{
        'status' = $status;
        'message' = $message
    }

    New-Object -TypeName PSObject -Property $props
}

# Simple checks to see if WinRM and DFSR Services are running
function Get-DfsrServiceStatus {

    $status = 0
    $message = "DFSR Service is running"
        
    if (!((Get-Service -Name DFSR).Status -eq "Running")) {
        $status = 2
        $message = "Warning. DFSR Service is stopped. Check DFSR service urgently."
    }
    
    $props = @{
        'message'= $message;
        'status' = $status
    }

    New-Object -TypeName PSObject -Property $props 
}

function Get-WinRMServiceStatus {
    
    $status = 0
    $message = "WinRM Service is running"
    
    if (!((Get-Service -Name WinRm).Status -eq "Running")) {
        $status = 1
        $message = "Warning. WinRM Service is stopped. This may cause alerts for DFSR backlog checks."
    }
    
    $props = @{
        'message' = $message;
        'status' = $status
    }
    
    New-Object -TypeName PSObject -Property $props 
}

# Get DFSR Backlog count
function Get-DfsrBacklogCount {
    [CmdletBinding()]
        Param (
            [Parameter(Mandatory=$true)]$dfsrGroup,
            [Parameter(Mandatory=$true)]$replicatedFolder,
            [Parameter(Mandatory=$true)]$dfsrSourceComputer,
            [Parameter(Mandatory=$true)]$dfsrDestinationComputer
        )

    $errorStatus = $false
    $backlogCount = 0
    
    try
    {
        $backlogmsg = ($null = $(Get-DfsrBacklog -GroupName $dfsrGroup -FolderName $replicatedFolder -SourceComputerName $dfsrSourceComputer -DestinationComputerName $dfsrDestinationComputer -Verbose)) 4>&1
    }
    catch 
    {
        $errorStatus = $true # Warning - unable to calculate backlog for specified folder
    }

    if ($backlogmsg -notmatch "No backlog for the replicated folder")
    {
        try
        {
            $backlogCount = [int]$($backlogmsg -replace "The replicated folder has a backlog of files. Replicated folder: `"$replicatedFolder`". Count: (\d+)",'$1')
        }
        Catch
        {
            $errorStatus = $true # Warning - unable to calculate backlog for specified folder
        }
    }
    $props = @{
        'BacklogCount'= $backlogCount;
        'ErrorStatus'= $errorStatus
    }

    New-Object -TypeName PSObject -Property $props 
}
# End region monitoring functions

# Region DFSR Healthcheck function
function Get-DfsrHealthCheck {
    [CmdletBinding()]
        Param (
            [Parameter(Mandatory=$true)]$folder,
            [Parameter(Mandatory=$true)]$WarnThreshold,
            [Parameter(Mandatory=$true)]$CritThreshold
        )

    $status = 0
    $message = "Warning, unable to enumerate DFSR backlog on $env:COMPUTERNAME. Check DFSR Replication health on server."

    $dfsrReplicatedFolderInfo = Get-DfsrFolderInformation -replicatedFolder $folder

    if ($dfsrReplicatedFolderInfo.ConnectionWarning)
    {
        $status = 2
        $message = "Warning, unable to calculate backlog for folder $folder on $env:COMPUTERNAME. Check DFSR health on server."
    }
    else 
    {
        $backlogCheck = Get-DfsrBacklogCount -replicatedFolder $folder -dfsrGroup $($dfsrReplicatedFolderInfo.DfsrGroup) -dfsrSourceComputer $env:COMPUTERNAME -dfsrDestinationComputer $($dfsrReplicatedFolderInfo.DfsrDestinationComputer)
    }
    
    if ($backlogCheck.ErrorStatus -eq $true)
    {
        $status = 2
        $message = "Warning, unable to calculate backlog for folder $folder on $env:COMPUTERNAME. Check DFSR health on server."
    }
    elseif ( $backlogCount -ge $critthreshold )
    {
    $status = 2
    $message = "Backlog count for folder `"$folder`" in replication group `"$($dfsrReplicatedFolderInfo.DfsrGroup)`" is $($backlogCheck.backlogCount). Check DFSR replication health urgently."
    }
    elseif ( $backlogCount -ge $warnThreshold )
    {
    $status = 1
    $message = "Backlog count for folder `"$folder`" in replication group `"$($dfsrReplicatedFolderInfo.DfsrGroup)`" is $($backlogCheck.backlogCount). Check DFSR replication health."
    }
    else
    {
    $status = 0
    $message = "Backlog count for folder `"$folder`" in replication group `"$($dfsrReplicatedFolderInfo.DfsrGroup)`" is $($backlogCheck.backlogCount). DFS Replication is healthy"
    }

    $props = @{
        'status' = $status;
        'message' = $message
    }
    New-Object -TypeName PSObject -Property $props 
}

function Test-DfsrReplicationHealth {
    [CmdletBinding()]
        Param (
            [Parameter(Mandatory=$true)]$replicatedfolder,
            [Parameter(Mandatory=$true)]$warnThreshold,
            [Parameter(Mandatory=$true)]$critthreshold
        )
    Foreach ($folder in $replicatedFolder) {
        
        Write-Verbose "Checking backlog for replicated folder $folder"
        $dfsrHealthcheck = Get-DfsrHealthCheck -folder $folder -WarnThreshold $warnThreshold -CritThreshold $critthreshold

        Write-Output "$($dfsrHealthcheck.status) DFSRReplicationCheck_$folder - $($dfsrHealthcheck.message)"
    }
}
# End region DFSR Healthcheck function


