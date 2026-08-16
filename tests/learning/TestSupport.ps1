$script:FailureCount = 0

function Assert-True([bool]$Condition, [string]$Message) {
  if (-not $Condition) { $script:FailureCount++; Write-Error "FAIL $Message" }
  else { Write-Host "PASS $Message" }
}

function Assert-Equal($Actual, $Expected, [string]$Message) {
  Assert-True ($Actual -eq $Expected) "$Message (actual=$Actual expected=$Expected)"
}

function Assert-Match([string]$Text, [string]$Pattern, [string]$Message) {
  Assert-True ($Text -match $Pattern) $Message
}

function Complete-TestFile {
  if ($script:FailureCount -gt 0) { throw "$script:FailureCount assertion(s) failed" }
}
