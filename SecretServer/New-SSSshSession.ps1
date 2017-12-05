<#

.Synopsis
Initiates Windows RDP connection to a server using secret retrieved from SecretServer database.

.Description
Initiates an RDP session to a Windows Device using credentials pulled from the Secret Server. This function will use the computername as a search string to look for an associated secret. If none is found you will be prompted to enter a secret ID. If multiple secrets are matched you will be prompted to choose the correct secret.

.Parameter Computername
CI Name or IP Address of device you want to connect to. Must be a Windows Server

.Parameter SecretId
Specify a Secret ID to convert to a credential object when connecting to the device

.Example
# Initiate SSH Connection to a server using the IP address
New-SsSshSession 212.181.160.12

.Example
# Initiate RDP Connection to a server by specifying the secret ID
New-SsSshSession mulinuxserver -SecretId 5478

#>

function New-SSSshSession{
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ComputerName,
        [System.string]$SecretId
    )

    $credential = Get-Secret -computername $Computername -SecretId $SecretId
    $password = $credential.password
    $connectionArgs = $user + "@" + $computername
    
    Write-Verbose "Launching putty session to $ComputerName using SecretID $($credential.SecretID)"
    & "C:\Program Files (x86)\PuTTY\putty.exe" -ssh $connectionArgs -pw $password
}