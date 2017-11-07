<#
To Do:
Add a threshold parameter for Get-DfsrCriticalEvents to tweak how far back the monitor checks.
Add a 'reset' parameter for Get-DfsrCriticalEvents to ignore anything before a specific time. 
Add support for more than one DFSRDestination server

Any issues with this module contact Tony Roud
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
        Write-Verbose "Checking DFSR Connection info for $replicatedFolder"
        $dfsrConnections = Get-DfsrConnection -GroupName $($dfsrFolderInfo.Groupname) | Where-Object { $_.SourceComputerName -eq $env:COMPUTERNAME }
    }
    catch 
    {
        $connectionWarning = $true  
        Write-Warning "Unable to get DFSR connection info for $replicatedFolder. Check DFSR health"
    }

    $props = @{ 'DfsrGroup' = $dfsrFolderInfo.Groupname
                'ReplicatedFolder' = $replicatedFolder
                'DfsrSourceComputer' = $dfsrConnections.SourceComputerName
                'DfsrDestinationComputer' = $dfsrConnections.DestinationComputerName
                'ConnectionWarning' = $connectionWarning
    }

    New-Object -Typename PSObject -Property $props
}

# Check for critical replication events in DFSR log (replication stopped on folder)
function Get-DfsrCriticalEvents {

    $status = 0
    $message = "No critical events found in DFSR log in the last 60 mins."

    Write-Verbose "Checking for critical events in the DFSR log within the last 60 minutes"
    $event = Get-EventLog -LogName "DFS Replication" -after ((Get-Date).addhours(-1)) | Where-Object { $_.message -match "DFS Replication service stopped replication on the replicated folder" }
    if ($event)
    {
        $status = 1
        $message = "Warning - Critical DFSR replication events found in the last 60 mins. Replication may have stopped for one or more replicated folders"
        Write-Warning "Warning - Critical DFSR replication events found in the last 60 mins. Replication may have stopped for one or more replicated folders"
    }
    else 
    {
        Write-Verbose "No critical events found in DFSR log in the last 60 mins."
    }
    $props = @{
        'status' = $status
        'message' = $message
    }

    New-Object -TypeName PSObject -Property $props
}

# Simple checks to see if WinRM and DFSR Services are running
function Get-DfsrServiceStatus {

    $status = 0
    $message = "DFSR Service is running"
        
    Write-Verbose "Checking status of DFSR service"
    if (!((Get-Service -Name DFSR).Status -eq "Running")) {
        $status = 2
        $message = "Warning. DFSR Service is stopped. Check DFSR service urgently."
        Write-Warning "Warning. DFSR Service is stopped. Check DFSR service urgently."
    }
    else 
    {
        Write-Verbose "DFSR Service is running"
    }
    $props = @{
        'message'= $message
        'status' = $status
    }

    New-Object -TypeName PSObject -Property $props 
}

function Get-WinRMServiceStatus {
    
    $status = 0
    $message = "WinRM Service is running"
    
    Write-Verbose "Checking status of WinRM Service"
    if (!((Get-Service -Name WinRm).Status -eq "Running")) {
        $status = 1
        $message = "Warning. WinRM Service is stopped. This may cause alerts for DFSR backlog checks."
        Write-Warning "Warning. WinRM Service is stopped. This may cause alerts for DFSR backlog checks."
    }
    else
    {
        Write-Verbose "WinRM service is running"
    }
    $props = @{
        'message' = $message
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

    $errorStatus = 0
    $backlogCount = "N/A"
    
    try
    {
        $backlogmsg = $( $null = Get-DfsrBacklog -GroupName $dfsrGroup -FolderName $replicatedFolder -SourceComputerName $dfsrSourceComputer -DestinationComputerName $dfsrDestinationComputer -Verbose -erroraction stop ) 4>&1
    }
    catch 
    {
        Write-Warning "Unable to calculate backlog information, check DFSR Services are running"
        $errorStatus = 1
    }

    if ($errorStatus -lt 1)
    {    
        if ($backlogmsg -match "No backlog for the replicated folder")
        {
            $backlogCount = 0
        }
        else 
        {
            try
            {
                $backlogCount = [int]$($backlogmsg -replace "The replicated folder has a backlog of files. Replicated folder: `"$replicatedFolder`". Count: (\d+)",'$1')
            }
            Catch
            {
                Write-Warning "Unable to extract backlog count from Get-DfsrBacklog output. Manually check the command is returning data for $replicatedFolder."
                $errorStatus = 1
            }
        }
    }

    $props = @{
        'BacklogCount'= $backlogCount
        'ErrorStatus'= $errorStatus
    }

    New-Object -TypeName PSObject -Property $props 
}
# End region monitoring functions

# Region DFSR Healthcheck functions
# These will call the monitoring functions and parse the values to generate the final output
function Get-DfsrHealthCheck {
    [CmdletBinding()]
        Param (
            [Parameter(Mandatory=$true)]$folder,
            [Parameter(Mandatory=$true)]$WarnThreshold,
            [Parameter(Mandatory=$true)]$CritThreshold
        )

<#
    $status = 1
    $message = "Warning, unable to enumerate DFSR backlog for folder `"$folder`". Check DFSR services are running on server."
#>
    $dfsrReplicatedFolderInfo = Get-DfsrFolderInformation -replicatedFolder $folder

    if ($dfsrReplicatedFolderInfo.ConnectionWarning)
    {
        $status = 2
        $message = "Unable to confirm connection details for folder $folder on $env:COMPUTERNAME. Check DFSR services are started."
        Write-Warning "Unable to confirm connection details for folder $folder on $env:COMPUTERNAME. Check DFSR services are started."
    }
    else
    {
        $backlogCheck = Get-DfsrBacklogCount -replicatedFolder $folder -dfsrGroup $($dfsrReplicatedFolderInfo.DfsrGroup) -dfsrSourceComputer $env:COMPUTERNAME -dfsrDestinationComputer $($dfsrReplicatedFolderInfo.DfsrDestinationComputer)
    
        if ($backlogCheck.ErrorStatus -eq 1)
        {
            $status = 2
            $message = "Unable to calculate backlog for folder $folder on $env:COMPUTERNAME. Check DFSR services are started."
            Write-Warning "Unable to calculate backlog for folder $folder on $env:COMPUTERNAME. Check DFSR services are started."
        }
        elseif ( $backlogCheck.backlogCount -ge $critthreshold )
        {
            $status = 2
            $message = "Backlog count for folder `"$folder`" in replication group `"$($dfsrReplicatedFolderInfo.DfsrGroup)`" is $($backlogCheck.backlogCount). Check DFSR replication health urgently."
            Write-warning "Backlog count for folder `"$folder`" in replication group `"$($dfsrReplicatedFolderInfo.DfsrGroup)`" is $($backlogCheck.backlogCount). Check DFSR replication health urgently."
        }
        elseif ( $backlogCheck.backlogCount -ge $warnThreshold )
        {
            $status = 1
            $message = "Backlog count for folder `"$folder`" in replication group `"$($dfsrReplicatedFolderInfo.DfsrGroup)`" is $($backlogCheck.backlogCount). Check DFSR replication health."
            Write-Warning "Backlog count for folder `"$folder`" in replication group `"$($dfsrReplicatedFolderInfo.DfsrGroup)`" is $($backlogCheck.backlogCount). Check DFSR replication health."
        }
        elseif ( $backlogCheck.backlogCount -gt 0 )
        {
            $status = 0
            $message = "Backlog count for folder `"$folder`" in replication group `"$($dfsrReplicatedFolderInfo.DfsrGroup)`" is $($backlogCheck.backlogCount)."
        }
        elseif ( $backlogCheck.backlogCount -eq 0 )
        {
            $status = 0
            $message = "Backlog count for folder `"$folder`" in replication group `"$($dfsrReplicatedFolderInfo.DfsrGroup)`" is 0."
        }
    }
    
    $props = @{
        'status' = $status
        'message' = $message
    }
    New-Object -TypeName PSObject -Property $props 
}

function Get-DfsrHealthCheckStatus {
    [CmdletBinding()]
        Param (
            [Parameter(Mandatory=$true)]$replicatedfolder,
            [Parameter(Mandatory=$true)]$warnThreshold,
            [Parameter(Mandatory=$true)]$critthreshold
        )
    
    # Perform healthcheck on replicated folder. 
    Write-Verbose "Checking backlog for replicated folder $replicatedfolder"
    $dfsrHealthcheck = Get-DfsrHealthCheck -folder $replicatedfolder -WarnThreshold $warnThreshold -CritThreshold $critthreshold
    Write-Output "$($dfsrHealthcheck.status) DFSReplicationCheck_$replicatedfolder - $($dfsrHealthcheck.message)"
    Write-Verbose "$($dfsrHealthcheck.status) DFSReplicationCheck_$replicatedfolder - $($dfsrHealthcheck.message)"

}
# End region DFSR Healthcheck function

Export-ModuleMember -function Get-DfsrFolderInformation,Get-DfsrCriticalEvents,Get-DfsrServiceStatus,Get-WinRMServiceStatus,Get-DfsrBacklogCount,Get-DfsrHealthCheck,Get-DfsrHealthCheckStatus