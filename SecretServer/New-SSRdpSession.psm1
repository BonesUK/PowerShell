<#

.Synopsys
Initiates Windows RDP connection to a server using SecretServer Module

.Description
Initiates an RDP session to a Windows Device using credentials pulled from the Secret Server. This function will use the computername as a search string to look for an associated secret. If none is found you will be prompted to enter a secret ID

.Parameter Computername
CI Name or IP Address of device you want to connect to. Must be a Windows Server

.Parameter SecretId
Specify a 4 digit Secret ID to convert to a credential object when connecting to the device

.Example
# Initiate RDP Connection to a server using the IP address
New-RdpSession 212.181.160.12

.Example
# Initiate RDP Connection to a server by specifying the secret ID
New-RdpSession 212.181.160.12 -SecretId 5478

#>

function New-RdpSession {
 
  param (
    [Parameter(Mandatory=$true,Position=1)]
    $ComputerName,
    [string]
    $SecretId
  )
 
  $ComputerName | ForEach-Object {
    if ($PSBoundParameters.ContainsKey('SecretID'))
    {
      $credential = (Get-Secret -SecretID $SecretID -As Credential).Credential
      $User = $Credential.UserName
      $Password = $Credential.GetNetworkCredential().Password
      cmdkey.exe /generic:$_ /user:$User /pass:$Password
    }
    else 
    {
       $credential = (Get-Secret -SearchTerm $ComputerName -As Credential).Credential
       if ($credential){
            $User = $Credential.UserName
            $Password = $Credential.GetNetworkCredential().Password
            cmdkey.exe /generic:$_ /user:$User /pass:$Password
       }
    }
    if ($credential)
    {
       mstsc.exe /v $_ /f
    }
    else 
    {
        Write-Warning "Unable to locate credential for $ComputerName"
        Write-Warning "Please try again using the parameter SecretID"
    }
  }
}


