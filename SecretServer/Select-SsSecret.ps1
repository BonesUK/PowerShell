<#
.Synopsis
    Enables user to select correct SecretID from multiple SecretServer database credential objects.

.Description
    Accepts input in the form of SecretServer credential objects and allows user to select a specific secretID which can then be passed back to commands such as New-SsServerConnection and New-SsRdpConnection.

.Parameter Searchterm
    Customer ID or name to search for associated entries in the SecretServer database.

.Example
    Select-SsSecret -Secretmatch $secrets
    This command will take the secret objects contained within the $secrets variable, and return the secret ID of the secret as a string for use in other cmdlets.

.Example
    $secrets = Get-Secret -SearchTerm customerid; Select-SsSecret -Secretmatch $secrets
    Pull secret objects into a variable then pipe to Select-SsSecret to get the desired SecretID.
#>
function Select-SsSecret {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)][Object[]]$secretmatch
    )
    
    Write-Host "ID`tSecretName"
    Write-Host "----`t------------------"

    Foreach ($secret in $secretmatch)
    {
        Write-Host "$($secret.secretID)`t$($secret.SecretName)"
    }

    [System.String]$secretSelection = Read-host "`nSelect a credential to use for this connection"

    Write-Verbose "Selected SecretID: $secretSelection"
    
    return $secretSelection
}