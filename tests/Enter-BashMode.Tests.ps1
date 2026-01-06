Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

BeforeAll {
  . "$PSScriptRoot\..\scripts\Enter-BashMode.ps1"
}

Describe "Invoke-Msys2BashSession" {
  It "runs a command and exits cleanly when exit is provided" {
    $result = Invoke-Msys2BashSession -InputLines @("echo __OK__","pwd","exit") -TimeoutSeconds 30
    $result.ExitCode | Should -Be 0
    ($result.StdOut -join "`n") | Should -Match "__OK__"
    $result.StdOut.Count | Should -BeGreaterThan 0
  }

  It "auto-sends exit if not provided" {
    $result = Invoke-Msys2BashSession -InputLines @("echo __AUTOEXIT__") -TimeoutSeconds 30
    $result.ExitCode | Should -Be 0
    ($result.StdOut -join "`n") | Should -Match "__AUTOEXIT__"
  }
}
