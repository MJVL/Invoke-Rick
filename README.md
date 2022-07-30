# Invoke-Rick
Rickroll someone's Windows desktop, restoring their original background occasionally to drive them mad.

Optionally restore the original background on mouse and/or keyboard activity.

For more fun, set this on auto-run through use of the registry, services, injecting into PowerShell modules, or more.

**Disclaimer:** I'm not responsible if this annoys blue or any other end user. I do not have ownership over any referenced imgur images or URLs, use at your own risk!

## One-liner
PowerShell
```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force; iwr https://raw.githubusercontent.com/MJVL/Invoke-Rick/main/Invoke-Rick.ps1 -OutFile Invoke-Rick.ps1; .\Invoke-Rick.ps1
```
Cmd
```
powershell.exe -ExecutionPolicy Bypass -NonInteractive -c "iwr https://raw.githubusercontent.com/MJVL/Invoke-Rick/main/Invoke-Rick.ps1 -OutFile Invoke-Rick.ps1; .\Invoke-Rick.ps1"
```


## Usage
```
SYNTAX
    .\Invoke-Rick.ps1 [[-URL] <String>] [[-ImagePath] <String>]
    [[-FrameDelay] <TimeSpan>] [[-FakeoutDelay] <TimeSpan>] [[-FakeoutDuration] <TimeSpan>] [[-EndTime] <DateTime>]
    [-WatchMouse] [-WatchKeyboard] [[-ActivityDelay] <TimeSpan>] [<CommonParameters>]

PARAMETERS
    -URL <String>
        Location of zip containing rickroll images. Default = imgur zip.

    -ImagePath <String>
        Location to save image frames. Default = C:\Windows\Temp\Rick.

    -FrameDelay <TimeSpan>
        Delay between each frame. Default = 1 second.

    -FakeoutDelay <TimeSpan>
        How long to rickroll until returning to the normal background. Default = 1 minute.

    -FakeoutDuration <TimeSpan>
        How long to remain on the normal background during a fakeout. Default = 5 minutes.

    -EndTime <DateTime>
        Absolute time to kill Invoke-Rick at. Default = run forever.

    -WatchMouse [<SwitchParameter>]
        Restore normal background if mouse movement is detected. Polling rate is linked with -FrameDelay.

    -WatchKeyboard [<SwitchParameter>]
        Restore normal background if keypresses is detected. Polling rate is linked with -FrameDelay.

    -ActivityDelay <TimeSpan>
        How long to remain on the normal background after detecting movement from the mouse or keyboard. Default = 1
        minute

    -Verbose
        Show debug information.

    -------------------------- EXAMPLE 1 --------------------------

    PS>iex powershell.exe -ExecutionPolicy Bypass -NonInteractive -c "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/MJVL/Invoke-Rick/blob/main/Invoke-Rick.ps1'))"
        Download and run this script remotely.

    -------------------------- EXAMPLE 2 --------------------------

    PS>.\Invoke-Rick.ps1 -WatchMouse -WatchKeyboard -ActivityDelay (New-TimeSpan -Seconds 30)
        Rickroll, restoring the original background for 30 seconds if keyboard or mouse activity is detected.

    -------------------------- EXAMPLE 3 --------------------------

    PS>.\Invoke-Rick.ps1 -FakeoutDuration (New-TimeSpan -Minutes 2) -EndTime ((Get-Date).AddMinutes(5))
        Rickroll for 5 minutes, showing the user's original background every 2 minutes.

    -------------------------- EXAMPLE 4 --------------------------

    PS>.\Invoke-Rick.ps1 -Verbose
        Show debug information.

    -------------------------- EXAMPLE 5 --------------------------

    PS>Get-Help .\Invoke-Rick.ps1 -Detailed
        Get detailed help.
```
