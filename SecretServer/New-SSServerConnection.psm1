<#
.SYNOPSIS
    Initiates connection to a server using a credential object retrieved from the SecretServer database.

.DESCRIPTION
    Initiates an RDP or SSH session to a device using credentials pulled from the Secret Server. This function will use the computername as a search string to look for an associated secret. If none is found you will be prompted to enter a secret ID. 

.PARAMETER Computername
    CI Name or IP Address of device you want to connect to. Can be a Windows or Linux server.

.PARAMETER SecretId
    Specify a Secret ID to pull from SecretServer and convert to a credential object when connecting to the device

.PARAMETER Protocol
    Use this switch to force connection via SSH or Rdp. If not specified the default will be Rdp.

.PARAMETER Searchterm
    Enter a searchterm such as customerID to search for associated secrets in the SecretServer database.

.EXAMPLE
    Initiate RDP Connection to a server using the IP address:
    New-SsServerConnection 212.181.160.12 -Protocol Rdp

.EXAMPLE
    Initiate SSH Connection to a server by specifying the secret ID:
    New-SsServerConnection MyLinuxServer -SecretId 5478 -Protocol Ssh

.EXAMPLE
    Initiate SSH Connection to multiple servers:
    New-SsServerConnection -Computername Windows1,Windows2,Windows3 -SecretID 1234 -Protocol Rdp

.EXAMPLE
    Launch RDP Session using computername and searchterm, using positional parameters:
    New-SSServerConnection 45.35.104.11 rdp -Searchterm CUSTOMERID
#>
function New-SSServerConnection {
    [cmdletbinding()]
    param 
    (
        [Parameter(Mandatory=$true,Position=1)]
        [System.String]$ComputerName,
        [Parameter(Position=3)]
        [System.String]$SecretId,
        [Parameter(Mandatory=$true,Position=2)]
        [ValidateSet('Rdp','Ssh')]
        [System.string]$Protocol="Rdp",
        [Parameter()]
        [System.String]$Searchterm
    )
  
    ForEach ($computer in $ComputerName)
    {
        if ($PSBoundParameters.ContainsKey('Searchterm'))
        {            
            Write-Verbose "No secretID specified. Searching for credentials matching searchterm $searchterm"
            $SecretID = Get-SSSecretDetails -SearchTerm $Searchterm
        }
        elseif (!$PSBoundParameters.ContainsKey('SecretID'))
        {   
            Write-Verbose "No secretID specified. Searching for credentials for $computername"
            $SecretID = Get-SSSecretDetails -SearchTerm $ComputerName
        }
        else 
        {
            $SecretID = (Get-Secret -SecretID $SecretID -As Credential).SecretID
        }
        if ($SecretID)
        {
            Write-Verbose "SecretID $SecretID was retrieved. Attempting to launch session."

            if ($Protocol -eq 'rdp') 
            { 
                Write-Verbose "Launching RDP Session to $computername using SecretID $secretID"
                New-SSRdpSession -ComputerName $computername -SecretID $secretID
            }
            else
            { 
                Write-Verbose "Launching Putty Session to $computername using SecretID $secretID"
                New-SsSshSession -Computername $computername -SecretID $secretID
            }
        }
        else 
        {
            Write-Warning "Unable to locate credential for $ComputerName"
            Write-Warning "Try again using the SecretID or Searchterm parameters."
        }
    }
}