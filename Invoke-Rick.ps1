[CmdletBinding()]
param(
    [string]$ZipPath,
    [string]$ImagePath = "C:\Windows\Temp\Rick\",
    [timespan]$FrameDelay = (New-TimeSpan -Seconds 1),
    [timespan]$FakeoutDelay = (New-TimeSpan -Minutes 1),
    [timespan]$FakeoutDuration = (New-TimeSpan -Minutes 5),
    [datetime]$EndTime
)

function Load-Frames {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DownloadPath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath,
        [string]$URL
    )
    # download from internet
    Write-Verbose "Expanding ZIP in $DestinationPath."
    try {
        Expand-Archive -Path $DownloadPath -DestinationPath $ImagePath -Force -ErrorAction Stop | Out-Null
        Write-Verbose "Expand success."
    }
    catch {
        $Error[0]
        Write-Verbose "Expand failed."
    }
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

    Write-Verbose "Downloading ZIP and loading images..."
    Load-Frames -DownloadPath $ZipPath -DestinationPath $ImagePath

    $images = (Get-ChildItem $ImagePath).FullName
    Write-Verbose "Found $($images.Count) images. Starting..."
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
finally {
    Set-WallPaper $original_wallpaper
}