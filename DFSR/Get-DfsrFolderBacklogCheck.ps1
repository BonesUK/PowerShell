function Get-DfsrFolderBacklogCheck {
    [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]$foldername,
            [Parameter(Mandatory=$true)]$rgSrc,
            [Parameter(Mandatory=$true)]$rgDst
        )
    
        $folder = Get-DfsReplicatedFolder -GroupName * -FolderName $foldername
    
        {
        Foreach ($dfsrPartner in $rgDst){
    
                $backlogmsg = ($null = $(Get-DfsrBacklog -FolderName $($folder.foldername) -SourceComputerName $rgSrc -DestinationComputerName $dfsrPartner -Verbose)) 4>&1
    
                if ($backlogmsg -match "No backlog for the replicated folder")
                {
                    $backlogCount = 0
                    $errormsg = "Backlog count for folder `"$($folder.foldername)`" in replication group `"$($folder.GroupName)`" is $backlogCount. DFS Replication is healthy"
                }
                else 
                {
                    try 
                    {
                        $backlogCount = [int]$($backlogmsg -replace "The replicated folder has a backlog of files. Replicated folder: `"$($folder.foldername)`". Count: (\d+)",'$1')
                    }
                    Catch
                    {
                        $status = 2
                        $errormsg = "Unable to calculate backlog for $($folder.foldername). Check status of DFSR on the server"
                    }
                }
                if ( $backlogCount -ge $critthreshold )
                {
                    $status = 2
                    $errormsg = "Backlog count for folder `"$($folder.foldername)`" in replication group `"$($folder.GroupName)`" is $backlogCount. Please check DFSR replication health urgently."
                }
                elseif ( $backlogCount -ge $warnThreshold )
                {
                    $status = 1
                    $errormsg = "Backlog count for folder `"$($folder.foldername)`" in replication group `"$($folder.GroupName)`" is $backlogCount. Please check DFSR replication health."
                }
                else
                {
                    $status = 0  
                    $errormsg = "Backlog count for folder `"$($folder.foldername)`" in replication group `"$($folder.GroupName)`" is $backlogCount. DFS Replication is healthy"
                }
            }
        } 
    
        $Props = @{ 
        'status' = $status;
        'errormsg' = $errormsg
        }
    
        $backlogoutput = New-Object -TypeName PSObject -Property $props 
        $backlogoutput
    }