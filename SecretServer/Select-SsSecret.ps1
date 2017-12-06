<#
.Synopsis
    Enables user to select correct SecretID from multiple SecretServer database credential objects.

.Description
    Accepts input in the form of SecretServer credential objects and allows user to select a specific secretID which can then be passed back to commands such as New-SsServerConnection and New-SsRdpConnection.

.Parameter Searchterm
    Customer ID or name to search for associated entries in the SecretServer database.

.Example
    Select-SsSecret -Secretmatch $secrets
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

    $secretmatch[$secretSelection].SecretID
    Write-Verbose "Returned SecretID $($secretmatch[$secretSelection].SecretID)"
}