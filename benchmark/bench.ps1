param(
    [string]$Sequential = ".\seq_add.bat",
    [string]$Parallel   = ".\parallel_add.bat",
    [int]$Runs = 7
)

function Get-Median($arr) {
    $s = $arr | Sort-Object
    $n = $s.Count
    $mid = [math]::Floor($n / 2)

    if ($n % 2 -eq 1) {
        return $s[$mid]
    } else {
        return ($s[$mid - 1] + $s[$mid]) / 2
    }
}

Write-Host "Benchmarking"
Write-Host "Sequential: $Sequential"
Write-Host "Parallel  : $Parallel"
Write-Host "Runs      : $Runs"
Write-Host ""

$seqTimes = @()
$parTimes = @()

Write-Host "Measuring sequential runs..."
for ($i = 1; $i -le $Runs; $i++) {
    $t = (Measure-Command { cmd /c $Sequential }).TotalMilliseconds
    $seqTimes += $t
    Write-Host "- Run $i : $([math]::Round($t,2)) ms"
}

Write-Host ""
Write-Host "Measuring parallel runs..."
for ($i = 1; $i -le $Runs; $i++) {
    $t = (Measure-Command { cmd /c $Parallel }).TotalMilliseconds
    $parTimes += $t
    Write-Host "- Run $i : $([math]::Round($t,2)) ms"
}

$seqMedian = Get-Median $seqTimes
$parMedian = Get-Median $parTimes

$speedup = $seqMedian / $parMedian

Write-Host ""
Write-Host "Sequential median : $([math]::Round($seqMedian,2)) ms"
Write-Host "Parallel median   : $([math]::Round($parMedian,2)) ms"
Write-Host "Speedup           : $([math]::Round($speedup,3))x"