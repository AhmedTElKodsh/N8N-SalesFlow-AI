. "$PSScriptRoot/TestSupport.ps1"

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$manifestPath = Join-Path $root 'release/release-manifest.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

$textExtensions = @('.env', '.example', '.json', '.sql', '.mjs', '.yaml', '.md', '.ps1', '.psm1')
foreach ($property in $manifest.inputHashes.PSObject.Properties) {
  $relativePath = [string]$property.Name
  $extension = [IO.Path]::GetExtension($relativePath).ToLowerInvariant()
  Assert-True ($textExtensions -contains $extension) "$relativePath uses a declared manifest text format"

  $attribute = @(& git -C $root check-attr eol -- $relativePath 2>&1)
  Assert-Equal $LASTEXITCODE 0 "git check-attr succeeds for $relativePath"
  Assert-Match ($attribute -join "`n") 'eol: lf$' "$relativePath is forced to LF"

  $path = Join-Path $root $relativePath
  Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "$relativePath exists"
  if (Test-Path -LiteralPath $path -PathType Leaf) {
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
    Assert-Equal $actual ([string]$property.Value).ToLowerInvariant() "raw manifest hash $relativePath"
  }
}

Complete-TestFile
