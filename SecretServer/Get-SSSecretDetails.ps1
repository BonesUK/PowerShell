<#

.Synopsis
Pulls all matching secrets from SecretServer and prompts user to select one to convert to credential object.

.Description
Retrieves all Secrets matching a searchterm and prompts user to select one to convert into a credential object for piping to other commands, such as New-SSServerConnection

.Parameter Searchterm
Customer ID or name to search for associated entries in the SecretServer database.

.Example
Retrieve all Secrets matching customer ID 1094756217
Get-SSSecretID -Searchterm 1094756217

#>

function Select-SSSecret {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)][Object[]]$secretmatch
    )
    
    Write-Host "No`tSecretID`tSecretName"
    Write-Host "==`t==========`t======================================="
    For ($i=1; $i -lt ($secretmatch.count)+1; $i++) 
    {
        $no = $i-1
        Write-Host "$i`t$($secretmatch[$no].SecretID)`t`t$($secretmatch[$no].Secretname)"
    }
    [Int]$secretSelection = ((Read-host "`nSelect a credential to use for this connection")-1)

    [Int]$secretID = $secretmatch[$secretSelection].SecretID

    return $secretID
}

function Get-SSSecretDetails {
    [cmdletbinding()]
    Param
    (
        [Parameter()][String]$Searchterm,
        [Parameter()][Switch]$Ssh
    )

    if ($PSBoundParameters.ContainsKey('Ssh'))
    {
        Write-Verbose "Searching for Linux passwords for $Searchterm. This may take a minute..."
        $Secrets = Get-Secret -SearchTerm $Searchterm -As Credential | Where-Object {$_.username -match 'root'}
    }
    else 
    {
        Write-Verbose "Attempting to locate Domain Admin credentials related to $searchterm"
        $Secrets = Get-Secret -SearchTerm $Searchterm | Where-Object {$_.secretname -match 'iomart|domain|admin' -and $_.secretname -notmatch 'firewall|switch|vpn'}            
    }
    if ($Secrets)
    {
        if ($Secrets.count -gt 1)
        {
            Write-Warning "Located $($Secrets.count) secrets associated with searchterm $searchterm :"
            Select-SsSecret -secretmatch $Secrets
        }
        else
        {
            Write-Verbose "Using SecretID: $($Secrets.SecretID) - $($Secrets.SecretName)"
            $SecretID = $Secrets.SecretID
        }
    }
    else
    {
        Write-Verbose "Unable to locate admin credential for $searchterm. Attempting to search for device credential"
        $Secrets = Get-Secret -SearchTerm $Searchterm

        if ($secrets)
        {
            if ($secrets.count -gt 1)
            {
                Write-Warning "Located $($secrets.count) secrets associated with searchterm $searchterm :"
                Select-SsSecret -secretmatch $secrets
            }
            else 
            {
                Write-Verbose "Located SecretID: $($secrets.SecretID) - $($secrets.SecretName)"
                $secretID = $secrets.secretID
            }
        }
        else 
        {
            Write-Warning "Unable to locate any valid credentials for $searchterm. You can try to connect again using the `'SecretID`' parameter if you know it."
        }
    }
    return $secretID
}

