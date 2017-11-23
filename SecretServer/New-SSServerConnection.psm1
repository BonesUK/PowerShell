<#

.Synopsys
Initiates connection to an item in your secretserver database using either SSH or RDP protocol

.Description
Initiates a session to a device using credentials pulled from the Secret Server. This function will use the computername as a search string to look for an associated secret. If none is found you will be prompted to enter a secret ID. You must specify connection type (either SSH or RDP).

.Parameter Computername
CI Name or IP Address of device you want to connect to. Can be either a Windows (RDP) or Linux (SSH) machine.

.Parameter SecretId
Specify a Secret ID to convert to a credential object when connecting to the device

.Example
# Initiate RDP Connection to a server using the IP address
New-IomServerConnection 212.181.160.12 -Rdp

.Example
# Initiate SSH Connection to a server by specifying the secret ID
New-IomServerConnection 212.181.160.12 -SecretId 5478 -Ssh

.Example 
# Initiate RDP Connection to multiple servers. Note you can only specify a single Secret ID for this track.
$machines = "225.64.25.46","FILESERVER02","64.22.11.23"; New-SSServerConnection -Computername $machines -Rdp

#>

function New-SSServerConnection {
 
  param 
  (
    [Parameter(Mandatory=$true,Position=1)]$ComputerName,
    [Switch]$Rdp,
    [Switch]$Ssh,
    [string]$SecretId
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
            cmdkey.exe /generic:$computername /user:$User /pass:$Password
       }
    }
    if ($credential)
    {
        if ($credential.count -lt 2) {
           if ($PSBoundParameters.ContainsKey('rdp')) { 
                    mstsc.exe /v $computername /f 
                }

           elseif ($PSBoundParameters.ContainsKey('ssh')){ 
                $connectionArgs = $user + "@" + $computername
                & "C:\Program Files (x86)\PuTTY\putty.exe" -ssh $connectionArgs -pw $password
           }
           else {
                Write-Warning "Please specify connection type using parameter -SSH or -RDP"
           }
        }
        Else {
            $matches = Get-Secret -Searchterm $computername
            Write-Warning "Multiple Secrets associated to this CI"
            Write-Warning "Matches: $($matches.secretID)"
            Write-Warning "Please try again specifying the correct SecretID"
        }
    }
    else 
    {
        Write-Warning "Unable to locate credential for $ComputerName"
        Write-Warning "Please try again using the parameter SecretID"
    }
  }
}

