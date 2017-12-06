<#
.Synopsis
    Initiates SSH connection to a linux server using secret retrieved from SecretServer database.

.Description
    Initiates an SSH session to a linux Device using credentials pulled from the Secret Server. This function will use the computername as a search string to look for an associated secret. If none is found you will be prompted to enter a secret ID. If multiple secrets are matched you will be prompted to choose the correct secret.

.Parameter Computername
    CI Name or IP Address of device you want to connect to. Must be a Windows Server

.Parameter SecretId
    Specify a Secret ID to convert to a credential object when connecting to the device

.Example
    Initiate SSH Connection to a server using the IP address:
    New-SsSshSession 212.181.160.12

.Example
    Initiate SSH Connection to a server by specifying the secret ID:
    New-SsSshSession mylinuxserver -SecretId 1234

.Example
    Initiate SSH connection using servername and searchterm:
    New-SsSshSession mylinuxserver -Searchterm customerid
#>
function New-SSSshSession{
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$ComputerName,
        [System.string]$SecretId,
        [System.string]$Searchterm
    )

    if ($PSBoundParameters.ContainsKey('Searchterm'))
    {
        $secretID = (Get-SSSecretDetails -SearchTerm $Searchterm -verbose -Ssh)
        $credential = (Get-Secret -SecretID $SecretID -As Credential).Credential
    }
    elseif (!$PSBoundParameters.ContainsKey('SecretID'))
    {
        $secretID = (Get-SSSecretDetails -SearchTerm $ComputerName -Ssh -verbose)
        $credential = Get-Secret -SearchTerm $Computername -SecretId $SecretId
    }
    else 
    {
        $credential = (Get-Secret -SecretID $SecretID -As Credential -verbose).Credential
    }
    if ($credential)
    {
        $User = $Credential.UserName
        $Password = $Credential.GetNetworkCredential().Password
        $connectionArgs = $user + "@" + $computername

        Write-Verbose "Launching putty session to $ComputerName using SecretID $($credential.SecretID)"
        & "C:\Program Files (x86)\PuTTY\putty.exe" -ssh $connectionArgs -pw $password
    }
    else 
    {
        Write-Warning "Something went wrong, no credential was found."
        Write-Warning "Try selecting a different credential or use the 'secretID' parameter"
    }
}