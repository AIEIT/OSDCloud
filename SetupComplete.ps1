Write-Output "========================================================="
Write-Output "Calling Custom Setup Complete File: $($PSCommandPath)"
Write-Output ""
Write-Output "CONFIRMED THIS RAN FROM FILE COPIED VIA FLASH DRIVE"
Write-Output ""
Write-Output "Completed Custom Setup Complete File: $($PSCommandPath)"
Write-Output "========================================================="

pause

# Inject Intel RST Driver into WinRE to fix Factory Reset / Wipes
switch ((Get-WmiObject Win32_Baseboard).Product) {
    'GU603ZM' { $driver = 'https://raw.githubusercontent.com/AIEIT/OSDCloud/main/Drivers/VMD_ROG_Intel_Z_V19.3.0.1016_28646_20240607160139.zip' }
    Default { $driver = $FALSE }
}

if($driver) {
    Invoke-WebRequest $driver -OutFile C:\OSDCloud\Scripts\SetupComplete\drivers.zip
}