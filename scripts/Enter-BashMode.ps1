Set-StrictMode -Version Latest

function Invoke-Msys2BashSession {
  [CmdletBinding()]
  param(
    [Parameter()][string]$BashPath = "",
    [Parameter(Mandatory = $true)][string[]]$InputLines,
    [Parameter()][int]$TimeoutSeconds = 15
  )

  if ([string]::IsNullOrEmpty($BashPath)) {
    $BashPath = Get-Msys2BashPath
  }

  if (-not (Test-Path -LiteralPath $BashPath)) {
    throw "MSYS2 bash not found at: $BashPath"
  }

  $script = ($InputLines -join "`n")

  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
  $p.StartInfo.FileName = $BashPath
  $p.StartInfo.Arguments = "--login"
  $p.StartInfo.UseShellExecute = $false
  $p.StartInfo.RedirectStandardInput = $true
  $p.StartInfo.RedirectStandardOutput = $true
  $p.StartInfo.RedirectStandardError = $true
  $p.StartInfo.CreateNoWindow = $true
  $p.StartInfo.EnvironmentVariables["MSYS"] = "disable_pcon"

  try {
    if (-not $p.Start()) {
      throw "Failed to start bash process."
    }

    $p.StandardInput.Write($script)
    $p.StandardInput.Close()

    $stdoutTask = $p.StandardOutput.ReadToEndAsync()
    $stderrTask = $p.StandardError.ReadToEndAsync()

    $waitMs = [Math]::Max(1, $TimeoutSeconds) * 1000
    if (-not $p.WaitForExit($waitMs)) {
      try { $p.Kill() } catch { }
      throw "bash session timed out after ${TimeoutSeconds}s and was terminated."
    }

    $stdoutResult = $stdoutTask.GetAwaiter().GetResult()
    $stderrResult = $stderrTask.GetAwaiter().GetResult()

    $stdoutLines = if ([string]::IsNullOrEmpty($stdoutResult)) {
      @()
    } else {
      @($stdoutResult -split "`r?`n" | Where-Object { $_ -ne "" })
    }

    $stderrLines = if ([string]::IsNullOrEmpty($stderrResult)) {
      @()
    } else {
      @($stderrResult -split "`r?`n" | Where-Object { $_ -ne "" })
    }

    [PSCustomObject]@{
      ExitCode = $p.ExitCode
      StdOut   = $stdoutLines
      StdErr   = $stderrLines
    }
  } finally {
    if (-not $p.HasExited) {
      try { $p.Kill() } catch { }
    }
    try { $p.Dispose() } catch { }
  }
}

function Get-Msys2BashPath {
  [CmdletBinding()]
  param()

  $candidates = @(
    "C:\msys64\usr\bin\bash.exe",
    "D:\msys64\usr\bin\bash.exe"
  )

  if ($env:RUNNER_TEMP) {
    $candidates = @("$env:RUNNER_TEMP\msys64\usr\bin\bash.exe") + $candidates
  }

  if ($env:MSYS2_ROOT) {
    $candidates = @("$env:MSYS2_ROOT\usr\bin\bash.exe") + $candidates
  }

  foreach ($path in $candidates) {
    if (Test-Path -LiteralPath $path) {
      return $path
    }
  }

  throw "MSYS2 bash.exe not found. Checked: $($candidates -join ', ')"
}

function Enter-BashMode {
  [CmdletBinding()]
  param(
    [Parameter()][string]$BashPath = ""
  )

  if ([string]::IsNullOrEmpty($BashPath)) {
    $BashPath = Get-Msys2BashPath
  }

  if (-not (Test-Path -LiteralPath $BashPath)) {
    throw "MSYS2 bash not found at: $BashPath"
  }

  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
  $p.StartInfo.FileName = $BashPath
  $p.StartInfo.Arguments = "--login -i"
  $p.StartInfo.UseShellExecute = $false
  $p.StartInfo.RedirectStandardInput = $true
  $p.StartInfo.RedirectStandardOutput = $true
  $p.StartInfo.RedirectStandardError = $true
  $p.StartInfo.CreateNoWindow = $true

  $outEvent = $null
  $errEvent = $null

  try {
    $outEvent = Register-ObjectEvent -InputObject $p -EventName OutputDataReceived -Action {
      if ($null -ne $EventArgs.Data) {
        Write-Host $EventArgs.Data
      }
    }

    $errEvent = Register-ObjectEvent -InputObject $p -EventName ErrorDataReceived -Action {
      if ($null -ne $EventArgs.Data) {
        Write-Host $EventArgs.Data -ForegroundColor Red
      }
    }

    if (-not $p.Start()) {
      throw "Failed to start bash process."
    }

    $p.BeginOutputReadLine()
    $p.BeginErrorReadLine()

    while ($true) {
      $cmd = Read-Host "bash$"
      if ($cmd -eq "exit") { break }
      $p.StandardInput.WriteLine($cmd)
    }
  } finally {
    if (-not $p.HasExited) {
      try { $p.StandardInput.WriteLine("exit") } catch { }
      try { $p.WaitForExit(3000) } catch { }
      try { $p.Kill() } catch { }
    }

    if ($null -ne $outEvent) {
      Unregister-Event -SourceIdentifier $outEvent.Name -ErrorAction SilentlyContinue
      Remove-Job -Name $outEvent.Name -Force -ErrorAction SilentlyContinue
    }

    if ($null -ne $errEvent) {
      Unregister-Event -SourceIdentifier $errEvent.Name -ErrorAction SilentlyContinue
      Remove-Job -Name $errEvent.Name -Force -ErrorAction SilentlyContinue
    }

    try { $p.Dispose() } catch { }
  }
}

Set-Alias bash Enter-BashMode
