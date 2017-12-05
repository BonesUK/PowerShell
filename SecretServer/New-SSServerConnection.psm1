<#

.Synopsis
Initiates connection to a server using a credential object retrieved from the SecretServer database.

.Description
Initiates an RDP or SSH session to a device using credentials pulled from the Secret Server. This function will use the computername as a search string to look for an associated secret. If none is found you will be prompted to enter a secret ID. 

.Parameter Computername
CI Name or IP Address of device you want to connect to. Can be a Windows or Linux server.

.Parameter SecretId
Specify a Secret ID to pull from SecretServer and convert to a credential object when connecting to the device

.Parameter Protocol
Use this switch to force connection via SSH or Rdp. If not specified the default will be Rdp.

.Parameter Searchterm
Enter a searchterm such as customerID to search for associated secrets in the SecretServer database.

.Example
# Initiate RDP Connection to a server using the IP address
New-SsServerConnection 212.181.160.12 -Rdp

.Example
# Initiate SSH Connection to a server by specifying the secret ID
New-SsServerConnection MyLinuxServer -SecretId 5478 -Ssh

.Example
# Initiate SSH Connection to multiple servers
New-SsServerConnection -Computername Windows1,Windows2,Windows3 -SecretID 1234 -Rdp

#>

function New-SSServerConnection {
    [cmdletbinding()]
    param 
    (
        [Parameter(Mandatory=$true,Position=1)]
        [System.String]$ComputerName,
        [Parameter(Position=2)]
        [System.String]$SecretId,
        [Parameter(Mandatory=$true,Position=3)]
        [ValidateSet('Rdp','Ssh')]
        [System.string]$Protocol="Rdp",
        [Parameter()]
        [System.String]$Crm
    )
  
    ForEach ($computer in $ComputerName)
    {
        if ($PSBoundParameters.ContainsKey('Crm'))
        {
            $SecretID = Get-SSSecretDetails -SearchTerm $Crm
        }
        elseif (!$PSBoundParameters.ContainsKey('SecretID'))
        {
            $SecretID = Get-SSSecretDetails -SearchTerm $ComputerName
        }
        else 
        {
        $SecretID = Get-SSSecretDetails -SearchTerm $SecretID
            if ($SecretID)
            {
                if ($PSBoundParameters.ContainsKey('rdp')) 
                { 
                    New-SSRdpSession -ComputerName $computername -SecretID $secretID
                }
                elseif ($PSBoundParameters.ContainsKey('ssh'))
                { 
                    New-SsSshSession -Computername $computername -SecretID $secretID
                }
                else 
                {
                    Write-Warning "Unable to locate credential for $ComputerName"
                    Write-Warning "Try again using the SecretID or CRM parameters."
                }
            }
        }
    }
}