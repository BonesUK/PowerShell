# Create new replication group
# Target folders need to be saved to a local text file with the same name as the replication group

# Replication group members
$DfsrMembers = "WEB1","WEB2"
$DfsrWeb1 = $DfsrMembers[0] 
$DfsrWeb2 = $DfsrMembers[1] 

# Replication group details:
$DfsrReplicationGroupName = Read-Host "Enter Replication Group Name"
$ReplicatedFolders = get-content "$DfsrReplicationGroupName.txt"

# Create Replication Group
New-DfsReplicationGroup -GroupName $DfsrReplicationGroupName 
New-DfsReplicatedFolder -GroupName $DfsrReplicationGroupName -FolderName $ReplicatedFolders 
Add-DfsrMember -GroupName $DfsrReplicationGroupName -ComputerName $DfsrMembers 

# Create DFSR Connection
Add-DfsrConnection -GroupName $DfsrReplicationGroupName -SourceComputerName $DfsrWeb1 -DestinationComputerName $DfsrWeb2

# Set membership on WEB1 (Primary)
Foreach ($ReplicatedFolder in $ReplicatedFolders) 
{ 
    Set-DfsrMembership -GroupName $DfsrReplicationGroupName -FolderName $ReplicatedFolder -ContentPath "D:\$ReplicatedFolder" -ComputerName $DfsrWeb1 -PrimaryMember $True -StagingPathQuotaInMB 250 -Force 
}

# Set membership on WEB2 (Secondary)
Foreach ($ReplicatedFolder in $ReplicatedFolders) 
{ 
    Set-DfsrMembership -GroupName $DfsrReplicationGroupName -FolderName $ReplicatedFolder -ContentPath "D:\$ReplicatedFolder" -ComputerName $DfsrWeb2 -StagingPathQuotaInMB 250 -Force # -DisableMembership:$True
}

# Make WEB1 Read-Only using Dfsradmin.exe
# Foreach ($ReplicatedFolder in $ReplicatedFolders) { Dfsradmin membership set /RGName:$DfsrReplicationGroupName /RFName:$ReplicatedFolder /MemName:REDTIE.LOCAL\$DfsrWeb1 /RO:true }
