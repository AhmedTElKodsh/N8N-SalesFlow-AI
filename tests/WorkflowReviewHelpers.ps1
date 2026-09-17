function Wait-WorkflowState([string]$Query,[string]$Expected,[string]$Label,[int]$TimeoutSeconds=30){
  $deadline=[DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
  do{$actual=@(docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 -qAtc $Query)-join"`n";if($LASTEXITCODE-ne0){throw "$Label observation query failed"};if($actual.Trim()-eq$Expected){Pass $Label;return};Start-Sleep -Milliseconds 200}while([DateTime]::UtcNow-lt$deadline)
  throw "$Label did not reach '$Expected' within $TimeoutSeconds seconds; observed '$($actual.Trim())'."
}
function Assert-HistoryFailure($Uri,$Headers,[int]$Status,[string]$Reason){
  $code=0;$content=''
  try{$response=Invoke-WebRequest $Uri -Method Post -Headers $Headers -ContentType application/json -Body '{}' -UseBasicParsing -TimeoutSec 15;$code=[int]$response.StatusCode;$content=$response.Content}
  catch{if(-not$_.Exception.Response){throw};$code=[int]$_.Exception.Response.StatusCode;if($_.ErrorDetails.Message){$content=$_.ErrorDetails.Message}else{$reader=[IO.StreamReader]::new($_.Exception.Response.GetResponseStream());try{$content=$reader.ReadToEnd()}finally{$reader.Dispose()}}}
  $body=$content|ConvertFrom-Json
  Assert ($code-eq$Status-and$body.result.reason-eq$Reason-and-not$body.result.ok-and$null-eq$body.result.messages) "history $Reason returns HTTP $Status without messages"
}
function Assert-HandoffDenial($Uri,$Headers,$RequestBody,[int]$Status,[string]$Reason){
  $code=0;$content=''
  try{$response=Invoke-WebRequest $Uri -Method Post -Headers $Headers -ContentType application/json -Body $RequestBody -UseBasicParsing -TimeoutSec 15;$code=[int]$response.StatusCode;$content=$response.Content}
  catch{if(-not$_.Exception.Response){throw};$code=[int]$_.Exception.Response.StatusCode;if($_.ErrorDetails.Message){$content=$_.ErrorDetails.Message}else{$reader=[IO.StreamReader]::new($_.Exception.Response.GetResponseStream());try{$content=$reader.ReadToEnd()}finally{$reader.Dispose()}}}
  $body=$content|ConvertFrom-Json
  Assert ($code-eq$Status-and$body.result.reason-eq$Reason-and-not$body.result.ok) "handoff $Reason returns HTTP $Status"
}
