<#
.Synopsis
   Pulls information from Cisco ASA syslog files and outputs into PowerShell objects
.DESCRIPTION
   Accepts input from Cisco syslogs in text format and extracts details such as IP protocol, source & destination IP address, port and interface. Requires Cisco syslog log file input in text format. Can be piped to normal formatting options.
.EXAMPLE
   Get-SyslogMessages -syslogfile syslog.txt -ports 443,80 -interfaces inside,outside
.EXAMPLE2
    Get-SyslogMessages -toptalkers 10 -target 192.168.2.45 -after 120117 -before 120617
#>

function Get-CiscoLogInfo
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
            $syslogfile,
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
            $interfaces,
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
            $ports
    )
    Begin
    {
        $interfaces = $interfaces
        $ipregex = "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
        $portregex = "\([0-9]*\)"
        $aclregex = "\['([^\]]+)'\]"
    }
    Process
    {
    $aclhits = get-content $syslogfile

        Foreach ($entry in $aclhits) { 

            $pos = $entry.IndexOf("permitted")
            $line = $entry.Substring($pos+10)

	        $ips = select-string $ipregex -input $line -AllMatches | ForEach-Object {$_.matches} 
            $ports = select-string $portregex -input $line -AllMatches | ForEach-Object {$_.matches} 
            $acl = select-string $aclregex -input $line -AllMatches | ForEach-Object {$_.matches}
            $ints = select-string $interfaces -input $line -AllMatches | ForEach-Object {$_.matches}

            $ReturnObjectProps = [ordered]@{

                'service'    = $line.substring(0,3)
                'SourceInt'  = $ints[0]
                'Source '    = $ips.value[0]
                'SourcePort' = $ports.value[0].ToString().Trim("(",")")
                'DestInt'    = $ints[1]
                'Dest'       = $ips.value[1]
                'DestPort'   = $ports.value[1].ToString().Trim("(",")")

                $outputObj = New-Object -TypeName psobject -Property $ReturnObjectProps
            }
	        $outputObj 
        }
    }
    End
    {
    }
}






