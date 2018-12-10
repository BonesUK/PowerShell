# Generate some random
$data = (-50..200) | get-random -count 39

function iqfinder {
    param($data)

    $data = $data | Sort-Object

    if((($data.count)/2) -is [double]){
        $q2 = $data[($data.count / 2) - 0.5]
        $q1 = $data[([math]::round(($data.count / 4),0))-1]
        $q3 = $data[(([math]::round(($data.count / 4),0))+(($data.count / 2) - 0.5))]
        $iq = $q3 - $q1

        Write-Host "Median is $q2"
        Write-Host "Range is "
        Write-Host "Q1 is $q1, Q3 is $q3"
        Write-Host "InterQuartile range is $iq"
    }
    if((($data.count)/2) -is [int]){
        $q2 = ($data[($data.count / 2)-1] + $data[($data.count / 2)])/2
        $q1 = (($data[([math]::round(($data.count / 4),0))-1]) + ($data[([math]::round(($data.count / 4),0))]))/2
        $q3 = ($data[($data.count * 0.75)] + ($data[(($data.count * 0.75)-1)])) / 2
        $iq = $q3 - $q1

    }

    $range =  $data[-1] - $data[0]
    $stats = $data | measure -AllStats

    [PSCustomObject]@{
        Q1            = $q1
        median        = $q2
        Q3            = $q3
        interquartile = $iq
        count         = $stats.Count
        average       = [math]::Round($stats.Average, 2)
        minimum       = $stats.Minimum
        maximum       = $stats.Maximum
        Range         = $range
        standarddeviation = [math]::Round($stats.StandardDeviation, 2)
    }
}