# Largely taken from https://github.com/jbedrech/WinPE_Autopilot/tree/main
Write-Host "Autopilot Device Registration Version 0.1"

# Config
$GroupTag = "OSDCloud"
$TimeServerUrl = "time.cloudflare.com"
$OutputFile = "X:\AutopilotHash.csv"
$TenantID = "your Azure Tenant ID goes here"
$AppID= "your AppID goes here"
$AppSecret = "your AppSecret goes here"

# Set the time
$DateTime = (Invoke-WebRequest -Uri $TimeServerUrl -UseBasicParsing).Headers.Date
Set-Date -Date $DateTime

# Create OA3 Hash
If((Test-Path X:\Windows\System32\wpeutil.exe) -and (Test-Path $PSScriptRoot\PCPKsp.dll))
{
	Copy-Item "$PSScriptRoot\PCPKsp.dll" "X:\Windows\System32\PCPKsp.dll"
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

# Upload the hash
Start-Sleep 30

#Get Modules needed for Installation
#PSGallery Support
Invoke-Expression(Invoke-RestMethod sandbox.osdcloud.com)
Install-module WindowsAutoPilotIntune -SkipPublisherCheck -Force

#Connection
Connect-MSGraphApp -Tenant $TenantId -AppId $AppId -AppSecret $AppSecret

#Import Autopilot CSV to Tenant
Import-AutoPilotCSV -csvFile $OutputFile
