$PATH_REMOTE_URL = "https://raw.githubusercontent.com/judigot/user/main/PATH"
$PATH_LOCAL_FILE = "$env:USERPROFILE\PATH"

function bash {
    param([string]$command)
    $env:HOME = $env:USERPROFILE
    $env:BASH_ENV = "$env:HOME\.bashrc"
    & C:/apportable/Programming/msys64/usr/bin/bash.exe --login -c $command
}

function Update-PathCache {
    $tmpFile = "$PATH_LOCAL_FILE.tmp"
    try {
        $response = Invoke-WebRequest -Uri $PATH_REMOTE_URL -UseBasicParsing -ErrorAction Stop
        if ($response.Content.Trim().Length -gt 0) {
            Set-Content -Path $tmpFile -Value $response.Content -NoNewline
            Move-Item -Path $tmpFile -Destination $PATH_LOCAL_FILE -Force
        } else {
            Remove-Item -Path $tmpFile -ErrorAction SilentlyContinue
        }
    } catch {
        Remove-Item -Path $tmpFile -ErrorAction SilentlyContinue
    }
}

if (Test-Path -Path $PATH_LOCAL_FILE) {
    $paths = Get-Content -Path $PATH_LOCAL_FILE -Raw
} else {
    try {
        $paths = (Invoke-WebRequest -Uri $PATH_REMOTE_URL -UseBasicParsing -ErrorAction Stop).Content
    } catch {
        $paths = ""
    }
}

if ($paths) {
    $pathsWindows = ($paths -split "`n" | Where-Object { $_.Trim() -ne "" }) -join ";"
    
    $currentPaths = $env:PATH -split ';' | Where-Object { $_.Trim() -ne '' }
    $newPaths = $pathsWindows -split ';' | Where-Object { $_.Trim() -ne '' }
    $pathsToAdd = $newPaths | Where-Object { $currentPaths -notcontains $_ }
    
    if ($pathsToAdd.Count -gt 0) {
        $env:PATH += ';' + ($pathsToAdd -join ';')
    }
}

Start-Job -ScriptBlock {
    param($RemoteUrl, $LocalFile)
    $tmpFile = "$LocalFile.tmp"
    try {
        $response = Invoke-WebRequest -Uri $RemoteUrl -UseBasicParsing -ErrorAction Stop
        if ($response.Content.Trim().Length -gt 0) {
            Set-Content -Path $tmpFile -Value $response.Content -NoNewline
            Move-Item -Path $tmpFile -Destination $LocalFile -Force
        } else {
            Remove-Item -Path $tmpFile -ErrorAction SilentlyContinue
        }
    } catch {
        Remove-Item -Path $tmpFile -ErrorAction SilentlyContinue
    }
} -ArgumentList $PATH_REMOTE_URL, $PATH_LOCAL_FILE | Out-Null

$env:NVM_HOME = "C:\apportable\Programming\nvm"
$env:NVM_SYMLINK = "C:\apportable\Programming\nodejs"
$env:NVM_DIR = "$env:USERPROFILE\.nvm"
$env:JAVA_HOME = "C:\apportable\Programming\jdk"

$env:SDKMAN_DIR = "C:\apportable\Programming\sdkman"

function Invoke-UpdateUserEnv { bash "source ~/.snippetsrc && shopt -s expand_aliases && eval updateUserEnv" }
Set-Alias -Name updateuserenv -Value Invoke-UpdateUserEnv
Set-Alias -Name updater -Value Invoke-UpdateUserEnv
Set-Alias -Name updaterc -Value Invoke-UpdateUserEnv
Set-Alias -Name updateenv -Value Invoke-UpdateUserEnv
Set-Alias -Name updatercfiles -Value Invoke-UpdateUserEnv
Set-Alias -Name updatebashsnippets -Value Invoke-UpdateUserEnv