param(
    [string]$action = "pull"  # pull 또는 push
)

Write-Host "=== Git Sync All Projects ===" -ForegroundColor Green
Write-Host "Root: C:\Working\OndeviceAI2\" -ForegroundColor Yellow
Write-Host "Action: $action" -ForegroundColor Cyan

$root = "C:\Working\OndeviceAI2"
$gitFolders = Get-ChildItem -Path $root -Recurse -Directory -Filter ".git" | 
              ForEach-Object { $_.Parent.FullName }

if ($gitFolders.Count -eq 0) {
    Write-Host "`n❌ Git repository not found!" -ForegroundColor Red
    exit
}

Write-Host "`n찾은 프로젝트: $($gitFolders.Count)개`n" -ForegroundColor Yellow

foreach ($projectPath in $gitFolders) {
    $projectName = Split-Path -Leaf $projectPath
    Write-Host "📁 $projectName" -ForegroundColor Cyan
    
    try {
        Push-Location $projectPath
        
        if ($action -eq "pull") {
            Write-Host "  📥 Pulling..." -ForegroundColor White
            git pull origin main 2>&1 | ForEach-Object { Write-Host "    $_" }
        } 
        elseif ($action -eq "push") {
            Write-Host "  📤 Pushing..." -ForegroundColor White
            git add . 2>&1 | Out-Null
            git commit -m "Auto sync from git-sync-all" 2>&1 | ForEach-Object { Write-Host "    $_" }
            git push origin main 2>&1 | ForEach-Object { Write-Host "    $_" }
        }
        
        Pop-Location
        Write-Host "  ✅ Complete`n" -ForegroundColor Green
    }
    catch {
        Write-Host "  ❌ Error: $_`n" -ForegroundColor Red
        Pop-Location
    }
}

Write-Host "=== All Done ===" -ForegroundColor Green