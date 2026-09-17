param()
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$container='salesflow-review-'+[guid]::NewGuid().ToString('N')
$launched=$false
function Query([string]$sql){
    $prior=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$output=@($sql|docker exec -i $container psql -X -U postgres -d postgres -v ON_ERROR_STOP=1 -qAt 2>&1);$code=$LASTEXITCODE}finally{$ErrorActionPreference=$prior}
    if($code-ne0){throw "Review SQL check failed: $($output -join [Environment]::NewLine)"}
    $output
}
try{
    if(-not(Get-Command docker -ErrorAction SilentlyContinue)){throw 'Docker is required for the focused database review checks.'}
    $manifest=Get-Content (Join-Path $root 'release/release-manifest.json') -Raw|ConvertFrom-Json
    $image=[string]$manifest.images[0]
    if($image-notmatch'^postgres@sha256:[a-f0-9]{64}$'){throw 'Pinned PostgreSQL image required.'}
    $password=[guid]::NewGuid().ToString('N')
    docker run --detach --rm --name $container --network none -e "POSTGRES_PASSWORD=$password" $image *> $null
    if($LASTEXITCODE-ne0){throw 'Could not start disposable PostgreSQL.'};$launched=$true
    $ready=$false;for($n=0;$n-lt60;$n++){docker exec $container pg_isready -U postgres *> $null;if($LASTEXITCODE-eq0){$ready=$true;break};Start-Sleep -Milliseconds 250};if(-not$ready){throw 'PostgreSQL readiness timed out.'}
    $migration=Get-Content (Join-Path $root 'database/001-initial.sql') -Raw
    $encoded=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($password))
    foreach($placeholder in @('__MIGRATION_PASSWORD_B64__','__WORKFLOW_DB_PASSWORD_B64__','__N8N_DB_PASSWORD_B64__')){$migration=$migration.Replace($placeholder,$encoded)}
    Query $migration|Out-Null;Query $migration|Out-Null
    Query "INSERT INTO salesflow.accounts VALUES('test-account',true);"|Out-Null
    foreach($file in Get-ChildItem (Join-Path $root 'config') -Filter *.json|Where-Object Name -ne 'account.json'){
        $doc=Get-Content $file.FullName -Raw|ConvertFrom-Json;$json=($doc|ConvertTo-Json -Compress -Depth 30).Replace("'","''")
        Query "INSERT INTO salesflow.config_docs(account_ref,kind,version,body,active)VALUES('test-account','$($doc.kind)','$($doc.version)','$json',true);"|Out-Null
    }
    Query (Get-Content (Join-Path $PSScriptRoot 'review-fixes.sql') -Raw)|ForEach-Object{Write-Host $_}
    & (Join-Path $PSScriptRoot 'Test-LocalTokenRenewalDatabase.ps1') -Container $container
    Write-Host 'PASS focused review database checks'
}finally{if($launched){docker rm --force --volumes $container *> $null;if($LASTEXITCODE-ne0){Write-Warning "Disposable review container cleanup failed; remove '$container' manually. This does not replace a real check failure above."}}}
