# Быстрое сохранение на GitHub (bekhruz9830/ai-chef)
# Запуск: правый клик -> "Выполнить с PowerShell" или в терминале: .\save_to_github.ps1 "описание изменений"

param([string]$Message = "Update")

Set-Location $PSScriptRoot

$status = git status -s
if (-not $status) {
    Write-Host "Нет изменений для коммита." -ForegroundColor Yellow
    exit 0
}

git add .
git commit -m $Message
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Отправка в main (на GitHub ветка main)
git push origin master:main
if ($LASTEXITCODE -ne 0) {
    Write-Host "Ошибка push. Если на GitHub уже есть другие коммиты, выполните:" -ForegroundColor Yellow
    Write-Host "  git pull origin main --allow-unrelated-histories" -ForegroundColor Cyan
    Write-Host "  (разрешите конфликты при необходимости)" -ForegroundColor Cyan
    Write-Host "  git push origin master:main" -ForegroundColor Cyan
    exit $LASTEXITCODE
}

Write-Host "Успешно сохранено на GitHub." -ForegroundColor Green
