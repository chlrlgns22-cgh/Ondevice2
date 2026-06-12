Write-Host "=== Initializing All Projects ===" -ForegroundColor Green

$root = "C:\Working\OndeviceAI2"
$dirs = Get-ChildItem -Path $root -Directory | Where-Object { $_.Name -notmatch "^\." }

$count = 0
foreach ($dir in $dirs) {
    $gitPath = Join-Path $dir.FullName ".git"
    
    if (-not (Test-Path $gitPath)) {
        Write-Host "📁 Initializing: $($dir.Name)" -ForegroundColor Cyan
        Push-Location $dir.FullName
        
        git init | Out-Null
        git config user.name "Your Name"
        git config user.email "your.email@example.com"
        git add . 2>$null
        git commit -m "Initial commit" 2>$null
        
        Pop-Location
        Write-Host "   ✅ Done" -ForegroundColor Green
        $count++
    }
    else {
        Write-Host "⏭️  Skipping: $($dir.Name) (already initialized)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Initialized: $count projects ===" -ForegroundColor Green