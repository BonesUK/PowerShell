<#
To do - Change so that generated password has at least 1 of each type of character in each complexity level
#>

<#
.Synopsis
    Generates a password and copies to the clipboard

.Description
    Generate a password of specified length and complexity. Then copies to the clipboard.

.Parameter Length
    Specify the required length of the password

.Parameter Complexity
    Specify a complexity level (1-4).
    1 - lowercase alphabetical characters only
    2 - lowercase and uppercase alphabetical characters
    3 - any alphanumeric character
    4 - alphanumeric and special characters.

.Example
    New-RandomPassword -length 10 -complexity 4
    [ I)hOyKS1Y5 ] copied to clipboard
#>
function New-RandomPassword {
    param(
        [Parameter(Mandatory=$True)][int]$length,
        [ValidateSet(1,2,3,4)][int]$complexity
    )
    $PassChars = (97..122) | ForEach-Object { [char]$_ }

    if ($complexity -gt 1) { $passChars += (65..90) | ForEach-Object { [char]$_ } }
    if ($complexity -gt 2) { $passChars += (0..9) }
    if ($complexity -gt 3) {

        $nonalphanumeric = '!£$%^&*()=+@#?'

        $PassChars += $nonalphanumeric.ToCharArray()

    }

    # $nonalphanumeric

    $pass = $passChars | Get-Random -Count $length
    $pass = $pass -join ''

    $pass | set-clipboard
    Write-Host "`[ $pass `] copied to clipboard"
}