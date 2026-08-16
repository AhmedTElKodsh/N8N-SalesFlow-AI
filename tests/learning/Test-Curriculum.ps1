. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$curriculum = Get-Content -Raw "$root/learning/curriculum.yaml" | ConvertFrom-Json
$template = Get-Content -Raw "$root/learning/progress-template.json" | ConvertFrom-Json

Assert-Equal $curriculum.curriculumVersion 1 'curriculum version'
Assert-Equal @($curriculum.milestones).Count 11 'M00-M10 count'
Assert-Equal (($curriculum.milestones.id) -join ',') ((0..10 | ForEach-Object { 'M{0:d2}' -f $_ }) -join ',') 'ordered milestone ids'
Assert-Equal @($curriculum.milestones[0].prerequisites).Count 0 'M00 has no prerequisites'
for ($i = 1; $i -le 10; $i++) {
  Assert-Equal $curriculum.milestones[$i].prerequisites[0] ('M{0:d2}' -f ($i - 1)) "M$i depends on predecessor"
}
Assert-Equal $template.schemaVersion 1 'progress schema version'
Assert-Equal $template.currentMilestone 'M00' 'initial milestone'
Assert-True ($null -ne $template.milestones.M00) 'M00 progress state exists'
Assert-Equal $template.milestones.M00.status 'available' 'M00 initially available'
Assert-Equal $template.milestones.M01.status 'locked' 'M01 initially locked'
Complete-TestFile
