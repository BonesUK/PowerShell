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
    Initiate RDP Connection to a server using the IP address
    New-SsRdpSession 212.181.160.12

.Example
    Initiate RDP Connection to a server by specifying the secret ID
    New-SsRdpSession 212.181.160.12 -SecretId 5478
#>
function New-SsRdpSession {
 
    param (
      [Parameter(Mandatory=$true,Position=1)]
      $ComputerName,
      [Parameter(Position=2)]
      [string]$SecretId,
      [string]$Searchterm
    )
    if ($PSBoundParameters.ContainsKey('Searchterm'))
    {
        $secretID = (Get-SSSecretDetails -SearchTerm $Searchterm -verbose)
        $credential = (Get-Secret -SecretID $SecretID -As Credential).Credential
    }
    elseif (!$PSBoundParameters.ContainsKey('SecretID'))
    {
        $secretID = (Get-SSSecretDetails -SearchTerm $ComputerName -verbose)
        $credential = (Get-Secret -SecretID $SecretID -As Credential).Credential
    }
    else 
    {
        $credential = (Get-Secret -SecretID $SecretID -As Credential -verbose).Credential
    }
    if ($credential)
    {
        $User = $Credential.UserName
        $Password = $Credential.GetNetworkCredential().Password
        cmdkey.exe /generic:$ComputerName /user:$User /pass:$Password
        mstsc.exe /v $ComputerName /f
    }
    else 
    {
        Write-Warning "Something went wrong, no credential was found."
        Write-Warning "Try selecting a different credential or use the 'secretID' parameter"
    }
}


