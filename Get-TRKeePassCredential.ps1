Function Get-TrKeePassEntry {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True,Position=1)][String]$KpKeyCode,
        [Parameter(Mandatory=$True,Position=2)][String]$KpProfileName
    )

    $kpEntry = Get-KeePassEntry -AsPlainText -DatabaseProfileName $KpProfileName -MasterKey $KpMasterKey -WarningAction:SilentlyContinue | Where-Object {$_.title -match $KpKeyCode}

    Write-Output "Found KeePass entry: $($kpEntry.title). Password copied to clipboard"
    $kpEntry | select-object -ExpandProperty password | Set-Clipboard

}