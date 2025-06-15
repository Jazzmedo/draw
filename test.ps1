# ✅ لازم تشغيل كـ Administrator

Write-Host ">> Killing Edge Update Tasks & Services..." -ForegroundColor Cyan

# 1. وقف وتعطيل خدمات Edge Update (لو موجودة)
$services = @("edgeupdate", "edgeupdatem")
foreach ($svc in $services) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "Disabled service: $svc" -ForegroundColor Green
    }
}

# 2. حذف المهام التلقائية من Task Scheduler
$tasks = @(
    "\Microsoft\EdgeUpdate\MicrosoftEdgeUpdateTaskMachineCore",
    "\Microsoft\EdgeUpdate\MicrosoftEdgeUpdateTaskMachineUA"
)

foreach ($task in $tasks) {
    $taskPath = $task.Split("\")[-2]
    $taskName = $task.Split("\")[-1]
$fullTaskPath = "\" + $taskPath + "\"
if (Get-ScheduledTask -TaskPath $fullTaskPath -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -TaskPath $fullTaskPath -Confirm:$false

        Write-Host "Deleted scheduled task: $task" -ForegroundColor Yellow
    }
}

# 3. حذف مفاتيح Registry الخاصة بسياسات Brave / Edge / Google
$regPaths = @(
    "HKLM:\SOFTWARE\Policies\BraveSoftware",
    "HKCU:\SOFTWARE\Policies\BraveSoftware",
    "HKLM:\SOFTWARE\Policies\Google",
    "HKCU:\SOFTWARE\Policies\Google",
    "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
)

foreach ($regPath in $regPaths) {
    if (Test-Path $regPath) {
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted registry key: $regPath" -ForegroundColor Gray
    }
}

# 4. قفل صلاحيات مجلد المهام ضد أي تعديل
$taskFolder = "$env:windir\System32\Tasks\Microsoft\EdgeUpdate"
if (Test-Path $taskFolder) {
    icacls $taskFolder /inheritance:r | Out-Null
    icacls $taskFolder /remove "Everyone" "Users" "SYSTEM" | Out-Null
    Write-Host "Locked EdgeUpdate task folder" -ForegroundColor Red
}

Write-Host "`nDone. Restart your PC to complete cleanup." -ForegroundColor Cyan
