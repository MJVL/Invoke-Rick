<#
.SYNOPSIS
    Rickroll someone's Windows desktop, restoring their original background occasionally to drive them mad.
.DESCRIPTION
    Rickroll someone's Windows desktop, restoring their original background occasionally to drive them mad.

    Disclaimer: I'm not responsible if this annoys blue or any other end user. 
                I do not have ownership over any referenced imgur images or URLs, use at your own risk!

    Author: @MJVL (https://github.com/MJVL)
.EXAMPLE
    PS> iex ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/MJVL/Invoke-Rick/blob/main/Invoke-Rick.ps1"))
        Download and run this script remotely. 
.EXAMPLE 
    PS> .\Invoke-Rick.ps1 -FakeoutDuration (New-TimeSpan -Minutes 2) -EndTime ((Get-Date).AddMinutes(5))
        Rickroll for 5 minutes, showing the user's original desktop every 2 minutes.
.EXAMPLE
    PS> .\Invoke-Rick.ps1 -Verbose
        Show debug information.
.EXAMPLE
    PS> Get-Help .\Invoke-Rick.ps1 -Detailed
        Get detailed help.
.LINK
    GitHub Repository: https://github.com/MJVL/Invoke-Rick
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Location of zip containing rickroll images. Default = imgur zip.")] # Location of zip containing rickroll images. Default = imgur zip.
    [ValidateNotNullOrEmpty()]
    [string]$URL = "https://zip.imgur.com/c36c1c4032df86f1f667e30665186a98ef35b4e0f632b0fa5e3ee3e8bfd6907c",
    [ValidateNotNullOrEmpty()]
    [Parameter(HelpMessage = "Location to save image frames. Default = C:\Windows\Temp\Rick.")] # Location to save image frames. Default = C:\Windows\Temp\Rick.
    [string]$ImagePath = "C:\Windows\Temp\Rick\",
    [ValidateNotNullOrEmpty()]
    [Parameter(HelpMessage = "Delay between each frame. Default = 1 second.")] # Delay between each frame. Default = 1 second.
    [timespan]$FrameDelay = (New-TimeSpan -Seconds 1),
    [ValidateNotNullOrEmpty()]
    [Parameter(HelpMessage = "How long to rickroll until returning to the user's normal background. Default = 1 minute.")] # How long to rickroll until returning to the user's normal background. Default = 1 minute.
    [timespan]$FakeoutDelay = (New-TimeSpan -Minutes 1),
    [Parameter(HelpMessage = "How long to remain on the user's normal background during a fakeout. Default = 5 minutes.")] # How long to remain on the user's normal background during a fakeout. Default = 5 minutes.
    [timespan]$FakeoutDuration = (New-TimeSpan -Minutes 5),
    [Parameter(HelpMessage = "Absolute time to kill Invoke-Rick at. Default = run forever.")] # Absolute time to kill Invoke-Rick at. Default = run forever.
    [datetime]$EndTime
)

function Get-Frames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$URL,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath
    )
    if (!(Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType "directory"
    }
    Remove-Item "$DestinationPath\*" -ErrorAction SilentlyContinue

    $zip_path = (Join-Path $DestinationPath "Rick.zip")
    try {
        Write-Verbose "Downloading ZIP..."
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $URL -OutFile $zip_path -ErrorAction Stop | Out-Null
    }
    catch {
        throw $Error[0]
    }

    Write-Verbose "Expanding ZIP in $DestinationPath."
    try {
        Expand-Archive -Path $zip_path -DestinationPath $DestinationPath -Force -ErrorAction Stop | Out-Null
        Write-Verbose "Expand success."
    }
    catch {
        throw $Error[0]
    }

    (Get-ChildItem $ImagePath).FullName
}

function Set-WallPaper {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
  
    if (!([System.Management.Automation.PSTypeName]"Params").Type) {
        Add-Type -TypeDefinition @" 
using System; 
using System.Runtime.InteropServices;
  
public class Params
{ 
    [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
    public static extern int SystemParametersInfo (Int32 uAction, Int32 uParam, String lpvParam, Int32 fuWinIni);
}
"@ -IgnoreWarnings
    }

    $SPI_SETDESKWALLPAPER, $UpdateIniFile, $SendChangeEvent = 0x0014, 0x01, 0x02
    $fWinIni = $UpdateIniFile -bor $SendChangeEvent
    [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Path, $fWinIni) | Out-Null
}

try {
    $original_wallpaper = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
    Write-Verbose "Original wallpaper: $original_wallpaper"
    
    $images = Get-Frames -URL $URL -DestinationPath $ImagePath -ErrorAction Stop
    Write-Verbose "Found $($images.Count) images, starting..."
    $checkpoint, $index = (Get-Date), 0
    while ($true) {
        if ($EndTime -and ((Get-Date) -gt $EndTime)) {
            Write-Verbose "Passed EndTime, exiting..."
            break
        }

        if ((Get-Date) -gt $checkpoint.AddSeconds($FakeoutDelay.TotalSeconds)) {
            Write-Verbose "Hit $FakeoutDelay, restoring to original and sleeping for $FakeoutDuration."
            Set-WallPaper $original_wallpaper
            Start-Sleep $FakeoutDuration.TotalSeconds
            $checkpoint = Get-Date
        }
        
        Set-WallPaper $images[$index]
        $index = ($index + 1) % $images.Length
        Start-Sleep $FrameDelay.TotalSeconds
    }
}
catch {
    Write-Verbose "Hit error, terminating:"
    Write-Verbose $Error[0].ToString()
}
finally {
    Remove-Item "$ImagePath\*" -ErrorAction SilentlyContinue
    Set-WallPaper $original_wallpaper
}