Set-StrictMode -Version Latest

function Invoke-Msys2BashSession {
  [CmdletBinding()]
  param(
    [Parameter()][string]$BashPath = "C:\msys64\usr\bin\bash.exe",
    [Parameter(Mandatory = $true)][string[]]$InputLines,
    [Parameter()][int]$TimeoutSeconds = 15
  )

  if (-not (Test-Path -LiteralPath $BashPath)) {
    throw "MSYS2 bash not found at: $BashPath"
  }

  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
  $p.StartInfo.FileName = $BashPath
  $p.StartInfo.Arguments = "-i"
  $p.StartInfo.UseShellExecute = $false
  $p.StartInfo.RedirectStandardInput = $true
  $p.StartInfo.RedirectStandardOutput = $true
  $p.StartInfo.RedirectStandardError = $true
  $p.StartInfo.CreateNoWindow = $true

  $stdout = New-Object System.Collections.Generic.List[string]
  $stderr = New-Object System.Collections.Generic.List[string]

  try {
    if (-not $p.Start()) {
      throw "Failed to start bash process."
    }

    $outTask = [System.Threading.Tasks.Task]::Run([Action]{
      while ($true) {
        $line = $p.StandardOutput.ReadLine()
        if ($line -eq $null) { break }
        [void]$stdout.Add($line)
      }
    })

    $errTask = [System.Threading.Tasks.Task]::Run([Action]{
      while ($true) {
        $line = $p.StandardError.ReadLine()
        if ($line -eq $null) { break }
        [void]$stderr.Add($line)
      }
    })

    $sentExit = $false
    foreach ($line in $InputLines) {
      if ($line -eq "exit") { $sentExit = $true }
      $p.StandardInput.WriteLine($line)
    }

    if (-not $sentExit) {
      $p.StandardInput.WriteLine("exit")
    }

    $waitMs = [Math]::Max(1, $TimeoutSeconds) * 1000
    if (-not $p.WaitForExit($waitMs)) {
      try { $p.Kill($true) } catch { }
      throw "bash session timed out after ${TimeoutSeconds}s and was terminated."
    }

    try {
      [void][System.Threading.Tasks.Task]::WaitAll(@($outTask, $errTask), 2000)
    } catch { }

    [PSCustomObject]@{
      ExitCode = $p.ExitCode
      StdOut   = $stdout.ToArray()
      StdErr   = $stderr.ToArray()
    }
  } finally {
    if (-not $p.HasExited) {
      try { $p.StandardInput.WriteLine("exit") } catch { }
      try { $p.WaitForExit(2000) } catch { }
      try { $p.Kill($true) } catch { }
    }
    try { $p.Dispose() } catch { }
  }
}

function Enter-BashMode {
  [CmdletBinding()]
  param(
    [Parameter()][string]$BashPath = "C:\msys64\usr\bin\bash.exe"
  )

  if (-not (Test-Path -LiteralPath $BashPath)) {
    throw "MSYS2 bash not found at: $BashPath"
  }

  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
  $p.StartInfo.FileName = $BashPath
  $p.StartInfo.Arguments = "-i"
  $p.StartInfo.UseShellExecute = $false
  $p.StartInfo.RedirectStandardInput = $true
  $p.StartInfo.RedirectStandardOutput = $true
  $p.StartInfo.RedirectStandardError = $true
  $p.StartInfo.CreateNoWindow = $true

  $outJob = $null
  $errJob = $null

  try {
    if (-not $p.Start()) {
      throw "Failed to start bash process."
    }

    $outJob = Start-Job -ArgumentList $p.StandardOutput -ScriptBlock {
      param($s)
      while (($line = $s.ReadLine()) -ne $null) { Write-Host $line }
    }

    $errJob = Start-Job -ArgumentList $p.StandardError -ScriptBlock {
      param($s)
      while (($line = $s.ReadLine()) -ne $null) { Write-Host $line }
    }

    while ($true) {
      $cmd = Read-Host "bash$"
      if ($cmd -eq "exit") { break }
      $p.StandardInput.WriteLine($cmd)
    }
  } finally {
    if (-not $p.HasExited) {
      try { $p.StandardInput.WriteLine("exit") } catch { }
      try { $p.WaitForExit(3000) } catch { }
      try { $p.Kill($true) } catch { }
    }

    if ($outJob -ne $null) {
      try { Stop-Job $outJob -ErrorAction SilentlyContinue | Out-Null } catch { }
      try { Remove-Job $outJob -ErrorAction SilentlyContinue | Out-Null } catch { }
    }

    if ($errJob -ne $null) {
      try { Stop-Job $errJob -ErrorAction SilentlyContinue | Out-Null } catch { }
      try { Remove-Job $errJob -ErrorAction SilentlyContinue | Out-Null } catch { }
    }

    try { $p.Dispose() } catch { }
  }
}

Set-Alias bash Enter-BashMode
