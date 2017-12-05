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
        [Parameter(Mandatory=$true)][Object[]]$Credential
    )
    
    Write-Output "No`tSecretID`tSecretName"
    Write-Output "==`t==========`t======================================="
    For ($i=1; $i -lt ($credential.count)+1; $i++) 
    {
        $no = $i-1
        Write-Output "$i`t$($credential[$no].SecretID)`t`t$($credential[$no].Secretname)"
    }
    [Int]$secretSelection = ((Read-host "`nSelect a credential to use for this connection")-1)
    try 
    {
        $secretID = $credential[$secretSelection].SecretID
        Write-Verbose "Retrieving SecretID $secretID"
        $credential = Get-Secret -SecretID $secretID -As Credential -erroraction stop -verbose
        Write-Verbose $credential
    }
    catch
    {
        Write-Warning "a Unable to locate Secret with ID $($credential[$secretSelection].SecretID)"
        Write-Warning "a Try connecting again by specifying the SecretID manually"
        Throw
    } 
}
function Get-SSSecretDetails {
    [cmdletbinding()]
    Param
    (
        [Parameter()][String]$Searchterm
    )

    Write-Verbose "Attempting to locate Domain Admin credentials related to $searchterm"
    $credential = Get-Secret -SearchTerm $Searchterm | Where-Object {$_.secretname -match 'iomart|domain admin' -and $_.secretname -notmatch 'firewall|switch'}
    
    if ($credential)
    {
        if ($credential.count -gt 1)
        {
            Write-Warning "d Located $($credential.count) secrets associated with searchterm $searchterm :"
            Select-SsSecret -Credential $credential
        }
        else
        {
            Write-Verbose "Using SecretID: $($credential.SecretID) - $($credential.SecretName)"
            $credential = Get-Secret -SecretID $credential.secretID -As Credential
        }
    }
    else
    {
        Write-Verbose "Unable to locate admin credential for $searchterm. Attempting to search for device credential"
        $Credential = Get-Secret -SearchTerm $Searchterm

        if ($credential)
        {
            if ($credential.count -gt 1)
            {
                Write-Warning "b Located $($credential.count) secrets associated with searchterm $searchterm :"
                Select-SsSecret -Credential $credential               
            }
            else 
            {
                Write-Verbose "Located SecretID: $($credential.SecretID) - $($credential.SecretName)"
                $credential = Get-Secret -SecretID $credential.secretID -As Credential
            }
        }
        else 
        {
            Write-Warning "c Unable to locate any valid credentials for $searchterm. You can try to connect again using the `'SecretID`' parameter if you know it."
        }
    }
    Write-Output $credential
    Write-Verbose $credential
}

