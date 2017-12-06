<#
.Synopsis
    Pulls all matching secrets from SecretServer and prompts user to select one to convert to credential object.

.Description
    Retrieves all Secrets matching a searchterm and prompts user to select one to retrieve the SecretID in order to pipe to other commands, such as New-SSServerConnection

.Parameter Searchterm
    Customer ID or name to search for associated entries in the SecretServer database.

.Example
    Retrieve all Secrets matching customer ID 1094756217
    Get-SSSecretID -Searchterm 1094756217
#>
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
            Select-SsSecret -secretmatch $Secrets -Verbose
        }
        else
        {
            Write-Verbose "Using SecretID: $($Secrets.SecretID) - $($Secrets.SecretName)"
            $Secrets.SecretID
        }
    }
    else
    {
        Write-Verbose "Unable to locate admin credential for `"$searchterm`". Attempting to search for device credential"
        $Secrets = Get-Secret -SearchTerm $Searchterm

        if ($secrets)
        {
            Write-Verbose "Found $($secrets.count) secrets"
            if ($secrets.count -gt 1)
            {
                Write-Warning "Located $($secrets.count) secrets associated with searchterm `"$searchterm`" :"
                Select-SsSecret -secretmatch $secrets -Verbose
            }
            else 
            {
                Write-Verbose "Located SecretID: $($secrets.SecretID) - $($secrets.SecretName)"
                $secrets.secretID
            }
        }
        else 
        {
            Write-Warning "Unable to locate any valid credentials for $searchterm. Try connecting again using the parameter SecretID or searchterm."
        }
    }
}
