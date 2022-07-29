# Invoke-Rick
Rickroll someone's Windows desktop, restoring their original background occasionally to drive them mad.


**Disclaimer:** I'm not responsible if this annoys blue or any other end user. I do not have ownership over any referenced imgur images or URLs, use at your own risk!

## One-liner
```PowerShell
iex ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/MJVL/Invoke-Rick/blob/main/Invoke-Rick.ps1"))
```

## Usage
```
SYNTAX
    C:\Users\micha\Documents\Development\Invoke-Rick\Invoke-Rick.ps1 [[-URL] <String>] [[-ImagePath] <String>] [[-FrameDelay] <TimeSpan>] [[-FakeoutDelay] <TimeSpan>] [[-FakeoutDuration] <TimeSpan>] [[-EndTime]        
    <DateTime>] [<CommonParameters>]


PARAMETERS
    -URL <String>
        Location of zip containing rickroll images. Default = imgur zip.

    -ImagePath <String>
        Location to save image frames. Default = C:\Windows\Temp\Rick.

    -FrameDelay <TimeSpan>
        Delay between each frame. Default = 1 second.

    -FakeoutDelay <TimeSpan>
        How long to rickroll until returning to the user's normal background. Default = 1 minute.

    -FakeoutDuration <TimeSpan>
        How long to remain on the user's normal background during a fakeout. Default = 5 minutes.

    -EndTime <DateTime>
        Absolute time to kill Invoke-Rick at. Default = run forever.

    -Verbose
        Show debug information.

    -------------------------- EXAMPLE 1 --------------------------

    PS>iex ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/MJVL/Invoke-Rick/blob/main/Invoke-Rick.ps1"))
        Download and run this script remotely.

    -------------------------- EXAMPLE 2 --------------------------

    PS>.\Invoke-Rick.ps1 -FakeoutDuration (New-TimeSpan -Minutes 2) -EndTime ((Get-Date).AddMinutes(5))
        Rickroll for 5 minutes, showing the user's original desktop every 2 minutes.

    -------------------------- EXAMPLE 3 --------------------------

    PS>.\Invoke-Rick.ps1 -Verbose
        Show debug information.

    -------------------------- EXAMPLE 4 --------------------------

    PS>Get-Help .\Invoke-Rick.ps1 -Detailed
        Get detailed help.
```
