<#
.SYNOPSIS
    Rickroll someone's Windows desktop, restoring their original background occasionally to drive them mad.
.DESCRIPTION
    Rickroll someone's Windows desktop, restoring their original background occasionally to drive them mad.

    Disclaimer: I'm not responsible if this annoys blue or any other end user. 
                I do not have ownership over any referenced imgur images or URLs, use at your own risk!

    Author: @MJVL (https://github.com/MJVL)
.EXAMPLE
    PS> Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/MJVL/Invoke-Rick/blob/main/Invoke-Rick.ps1"))
        Download and run this script remotely.
.EXAMPLE 
    PS>.\Invoke-Rick.ps1 -WatchMouse -WatchKeyboard -ActivityDelay (New-TimeSpan -Seconds 30)
        Rickroll, restoring the original background for 30 seconds if keyboard or mouse activity is detected.
.EXAMPLE 
    PS> .\Invoke-Rick.ps1 -FakeoutDuration (New-TimeSpan -Minutes 2) -EndTime ((Get-Date).AddMinutes(5))
        Rickroll for 5 minutes, showing the user's original background every 2 minutes.
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
    [string]$URL = "https://imgur.com/a/QTMaCss/zip",
    [ValidateNotNullOrEmpty()]
    [Parameter(HelpMessage = "Location to save image frames. Default = C:\Windows\Temp\Rick.")] # Location to save image frames. Default = C:\Windows\Temp\Rick.
    [string]$ImagePath = "C:\Windows\Temp\Rick\",
    [ValidateNotNullOrEmpty()]
    [Parameter(HelpMessage = "Delay between each frame. Default = 1 second.")] # Delay between each frame. Default = 1 second.
    [timespan]$FrameDelay = (New-TimeSpan -Seconds 1),
    [ValidateNotNullOrEmpty()]
    [Parameter(HelpMessage = "How long to rickroll until returning to the normal background. Default = 5 minutes.")] # How long to rickroll until returning to the normal background. Default = 1 minute.
    [timespan]$FakeoutDelay = (New-TimeSpan -Minutes 5),
    [Parameter(HelpMessage = "How long to remain on the normal background during a fakeout. Default = 5 minutes.")] # How long to remain on the normal background during a fakeout. Default = 5 minutes.
    [ValidateNotNullOrEmpty()]
    [timespan]$FakeoutDuration = (New-TimeSpan -Minutes 5),
    [Parameter(HelpMessage = "Absolute time to kill Invoke-Rick at. Default = run forever.")] # Absolute time to kill Invoke-Rick at. Default = run forever.
    [ValidateNotNullOrEmpty()]
    [datetime]$EndTime,
    [Parameter(HelpMessage = "Restore normal background if mouse movement is detected. Polling rate is linked with -FrameDelay.")] # Restore normal background if mouse movement is detected. Polling rate is linked with -FrameDelay.
    [switch]$WatchMouse,
    [Parameter(HelpMessage = "Restore normal background if keypresses are detected. Polling rate is linked with -FrameDelay.")] # Restore normal background if keypresses is detected. Polling rate is linked with -FrameDelay.
    [switch]$WatchKeyboard,
    [Parameter(HelpMessage = "How long to remain on the normal background after detecting movement from the mouse or keyboard. Default = 1 minute.")] # How long to remain on the normal background after detecting movement from the mouse or keyboard. Default = 1 minute
    [ValidateNotNullOrEmpty()]
    [timespan]$ActivityDelay = (New-Timespan -Minutes 1)
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

function Set-Wallpaper {
    [CmdletBinding()]
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

function Get-Keypress {
    [CmdletBinding()]
    param()
    if (!(([System.Management.Automation.PSTypeName]"Keyboard.KeypressWatcher").Type)) {
        Add-Type -MemberDefinition @"
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
"@ -IgnoreWarnings -Name KeypressWatcher -Namespace Keyboard
    }
    1..254 | ForEach-Object {
        if ([Keyboard.KeypressWatcher]::GetAsyncKeyState($_) -eq -32767) {
            return $_
        }
    }
    0
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
            Set-Wallpaper $original_wallpaper
            Start-Sleep $FakeoutDuration.TotalSeconds
            $checkpoint = Get-Date
        }

        if ($WatchMouse) {
            Add-Type -AssemblyName System.Windows.Forms
            $new_position = [System.Windows.Forms.Cursor]::Position
            Write-Verbose "Current Mouse Pos ($new_position) | Last Mouse Pos ($last_position)"
            if ($null -ne $last_position -and $new_position -ne $last_position) {
                Write-Verbose "Detected mouse movement, restoring to original and sleeping for $ActivityDelay."
                Set-Wallpaper $original_wallpaper
                Start-Sleep $ActivityDelay.TotalSeconds
            }
            $last_position = $new_position
        }

        if ($WatchKeyboard) {
            $new_keypress = Get-Keypress
            if ($null -ne $last_keypress -and $new_keypress -ne 0 -and $new_keypress -ne $last_keypress) {
                Write-Verbose "Detected keypress, restoring to original and sleeping for $ActivityDelay."
                Set-Wallpaper $original_wallpaper
                Start-Sleep $ActivityDelay.TotalSeconds
            }
            $last_keypress = $new_keypress
        }
        Set-Wallpaper $images[$index]
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
    Set-Wallpaper $original_wallpaper
}