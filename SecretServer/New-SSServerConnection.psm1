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

.PARAMETER Showall
    Specify this parameter to bypass the default behaviour of listing Domain/Admin credentials, and list all credentials matching the device name or searchterm.

.EXAMPLE
    New-SsServerConnection 212.181.160.12 -Protocol Rdp
    Initiate RDP Connection to a server using the IP address
    
.EXAMPLE
    New-SsServerConnection MyLinuxServer -SecretId 5478 -Protocol Ssh
    Initiates an SSH Connection to a server by specifying the secret ID

.EXAMPLE
    New-SsServerConnection -Computername Windows1,Windows2,Windows3 -SecretID 1234 -Protocol Rdp    
    Initiates an SSH Connection to multiple servers with a specified secretID.
    Note only one SecretID can be selected so the command will only work for devices that use the same credentials.

.EXAMPLE
    New-SSServerConnection 45.35.104.11 rdp -Searchterm CUSTOMERID
    Launches RDP Session using computername and searchterm, using positional parameters:
#>
function New-SsServerConnection {
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
        [System.String]$Searchterm,
        [Parameter()]
        [Switch]$Showall
    )
  
    ForEach ($computer in $ComputerName)
    {
        if ($PSBoundParameters.ContainsKey('Searchterm'))
        {            
            Write-Verbose "No secretID specified. Searching for credentials matching searchterm $searchterm"
            $SecretID = Get-SSSecretDetails -SearchTerm $Searchterm -Showall:$showall
        }
        elseif (!$PSBoundParameters.ContainsKey('SecretID'))
        {   
            Write-Verbose "No secretID specified. Searching for credentials for $computername"
            $SecretID = Get-SSSecretDetails -SearchTerm $ComputerName -Showall:$showall
        }
        else 
        {
            Write-Verbose "Looking for Secret matching ID $secretID"
            $SecretID = (Get-Secret -SecretID $SecretID -As Credential -ErrorAction SilentlyContinue).SecretID
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
            Write-Warning "Failed to load credential for $ComputerName"
            Write-Warning "Try again using the SecretID or Searchterm parameters."
        }
    }
}