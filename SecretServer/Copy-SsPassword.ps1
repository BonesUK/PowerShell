<#
.Synopsis
    Copies password for specified secret to the clipboard

.Description
    Copies password for specified secret to the clipboard

.Parameter SecretID
    Specify the SecretID to retrieve from the Secrets database and copy the password from.

.Example
    Copy password for secret 1234
    Copy-SsPassword -SecretID 1234
#>
function Copy-SsPassword {
    [CmdletBinding()]
    Param(
        $SecretID
    )

    $secret = (get-secret -SecretId $SecretID -As credential -ErrorAction SilentlyContinue).credential

    if ($secret)
    {
        try 
        {
            $secret.GetNetworkCredential().Password | set-clipboard
            Write-Host "Password for $($secret.Username) copied to clipboard."
        }
        catch 
        {
            Write-Warning "Unable to copy password for secret $SecretID."
        }
    }
    else 
    {
        Write-Warning "Couldn't locate Secret $secretID. Try another secret."
    }
}