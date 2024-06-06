# Settings
$OSName = 'Windows 11 23H2 x64'
$OSEdition = 'Education'
$OSActivation = 'Retail'
$OSLanguage = 'en-us'

#Set Global OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    BrandName = "AIE OSDCloud"
    BrandColor = "#0096FF"
    Restart = [bool]$False
    RecoveryPartition = [bool]$True
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$True
    WindowsUpdateDrivers = [bool]$True
    WindowsDefenderUpdate = [bool]$True
    SetTimeZone = [bool]$True
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$True
    CheckSHA1 = [bool]$True
}
Write-Host "Version 0.3 by MP"
Start-Sleep 5

Write-Host "Autopilot registering this device and uploading hash"
start /wait PowerShell -NoL -C Invoke-WebPSScript 'https://raw.githubusercontent.com/AIEIT/OSDCloud/main/Autopilot.ps1'

Write-Host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"
Start-Sleep 5
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage
