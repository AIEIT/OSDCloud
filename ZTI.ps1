# Largely taken from https://github.com/jbedrech/WinPE_Autopilot/tree/main
Write-Host "Autopilot Device Registration & Windows ZTI v1.0"

# --- Config ---
$GroupTag = "OSDCloud"
$TimeServerUrl = "time.cloudflare.com"
$OutputFile = "X:\AutopilotHash.csv"
$TenantID = [Environment]::GetEnvironmentVariable('OSDCloudAPTenantID','Machine') # $env:OSDCloudAPTenantID doesn't work within WinPe
$AppID = [Environment]::GetEnvironmentVariable('OSDCloudAPAppID','Machine')
$AppSecret = [Environment]::GetEnvironmentVariable('OSDCloudAPAppSecret','Machine')
$OSName = 'Windows 11 23H2 x64'
$OSEdition = 'Education'
$OSActivation = 'Retail'
$OSLanguage = 'en-us'
$Global:MyOSDCloud = [ordered]@{
    BrandName = "AIE OSDCloud"
    BrandColor = "#0096FF"
    Restart = [bool]$True
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

# --- END CONFIG ---

# Set the time
$DateTime = (Invoke-WebRequest -Uri $TimeServerUrl -UseBasicParsing).Headers.Date
Set-Date -Date $DateTime

# Download required files
$oa3tool = 'https://raw.githubusercontent.com/AIEIT/OSDCloud/main/oa3tool.exe'
$pcpksp = 'https://raw.githubusercontent.com/AIEIT/OSDCloud/main/PCPKsp.dll'
$inputxml = 'https://raw.githubusercontent.com/AIEIT/OSDCloud/main/input.xml'
$oa3cfg = 'https://raw.githubusercontent.com/AIEIT/OSDCloud/main/OA3.cfg'

Invoke-WebRequest $oa3tool -OutFile $PSScriptRoot\oa3tool.exe
Invoke-WebRequest $pcpksp -OutFile X:\Windows\System32\PCPKsp.dll
Invoke-WebRequest $inputxml -OutFile $PSScriptRoot\input.xml
Invoke-WebRequest $oa3cfg -OutFile $PSScriptRoot\OA3.cfg

# Create OA3 Hash
If((Test-Path X:\Windows\System32\wpeutil.exe) -and (Test-Path X:\Windows\System32\PCPKsp.dll))
{
	#Register PCPKsp
	rundll32 X:\Windows\System32\PCPKsp.dll,DllInstall
}

#Change Current Diretory so OA3Tool finds the files written in the Config File 
&cd $PSScriptRoot

#Get SN from WMI
$serial = (Get-WmiObject -Class Win32_BIOS).SerialNumber

#Run OA3Tool
&$PSScriptRoot\oa3tool.exe /Report /ConfigFile=$PSScriptRoot\OA3.cfg /NoKeyCheck

#Check if Hash was found
If (Test-Path $PSScriptRoot\OA3.xml) 
{
	#Read Hash from generated XML File
	[xml]$xmlhash = Get-Content -Path "$PSScriptRoot\OA3.xml"
	$hash=$xmlhash.Key.HardwareHash

	$computers = @()
	$product=""
	# Create a pipeline object
	$c = New-Object psobject -Property @{
 		"Device Serial Number" = $serial
		"Windows Product ID" = $product
		"Hardware Hash" = $hash
		"Group Tag" = $GroupTag
	}
	
 	$computers += $c
	$computers | Select "Device Serial Number", "Windows Product ID", "Hardware Hash", "Group Tag" | ConvertTo-CSV -NoTypeInformation | % {$_ -replace '"',''} | Out-File $OutputFile
}

#Get Modules needed for Installation
#PSGallery Support
# Invoke-Expression(Invoke-RestMethod sandbox.osdcloud.com)
Install-Module WindowsAutoPilotIntune -SkipPublisherCheck -Force

#Connection
Connect-MSGraphApp -Tenant $TenantId -AppId $AppId -AppSecret $AppSecret

#Import Autopilot CSV to Tenant
Import-AutoPilotCSV -csvFile $OutputFile

# Upload the hash
Start-Sleep 10

# Windows ZTI
Write-Host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage
