Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

BeforeAll {
  . "$PSScriptRoot\..\scripts\Enter-BashMode.ps1"
}

Describe "Invoke-Msys2BashSession" {
  It "runs a command and exits cleanly when exit is provided" {
    $result = Invoke-Msys2BashSession -InputLines @("echo __OK__", "pwd", "exit") -TimeoutSeconds 30

    Write-Host "ExitCode: $($result.ExitCode)"
    Write-Host "StdOut count: $($result.StdOut.Count)"
    Write-Host "StdOut: $($result.StdOut -join '|')"
    Write-Host "StdErr count: $($result.StdErr.Count)"
    Write-Host "StdErr: $($result.StdErr -join '|')"

    $result.ExitCode | Should -Be 0
    $result.StdOut.Count | Should -BeGreaterThan 0
    ($result.StdOut -join "`n") | Should -Match "__OK__"
  }

  It "auto-sends exit if not provided" {
    $result = Invoke-Msys2BashSession -InputLines @("echo __AUTOEXIT__") -TimeoutSeconds 30

    Write-Host "ExitCode: $($result.ExitCode)"
    Write-Host "StdOut count: $($result.StdOut.Count)"
    Write-Host "StdOut: $($result.StdOut -join '|')"
    Write-Host "StdErr count: $($result.StdErr.Count)"
    Write-Host "StdErr: $($result.StdErr -join '|')"

    $result.ExitCode | Should -Be 0
    ($result.StdOut -join "`n") | Should -Match "__AUTOEXIT__"
  }

  It "can detect MSYS2 bash path" {
    $bashPath = Get-Msys2BashPath
    Write-Host "Detected bash path: $bashPath"
    $bashPath | Should -Not -BeNullOrEmpty
    Test-Path -LiteralPath $bashPath | Should -Be $true
  }
}
