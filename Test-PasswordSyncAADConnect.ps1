$HeartBeatTime = $null
$message = $null

$heartbeat = Get-EventLog application | Where-Object {$_.eventid -eq 4627} | Select-Object -first 1

if (!$heartbeat) {
    $status = 2
    $message = "CRIT - No heartbeat event found. Please check Azure AD Sync urgently."
}
else {

    $HeartBeatTime = $heartbeat.TimeGenerated

    if ( $HeartBeatTime -gt (get-date).AddMinutes(-30) ) {
        $status = 0
        $message = "Healthy: Azure AD Password Sync heartbeat event found within the last 30 mins. Last heartbeat event occurred $HeartBeatTime."
    }
    elseif ( $HeartBeatTime -gt (get-date).AddHours(-1) ) {
        $status = 1
        $message = "WARN: Azure AD Password syncHeartbeat not found within the last 30 miconniins. Last heartbeat event occurred $HeartBeatTime."
    }
    else {
        $status = 2
        $message = "CRIT: Last hearbeat event was $HeartBeatTime. Please check Azure AD Sync urgently."
    }
}

Write-Output "$status AzureADPasswordSync - $message"
