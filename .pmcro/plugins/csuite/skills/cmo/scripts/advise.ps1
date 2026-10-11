[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$MessagePath,[string]$OutputPath='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not(Test-Path -LiteralPath $MessagePath -PathType Leaf)){throw 'message file missing'}
$raw=Get-Content -LiteralPath $MessagePath -Raw
try{$m=$raw|ConvertFrom-Json -DateKind String}catch{$m=$raw|ConvertFrom-Json}
$role=[string]$env:PMCRO_TARGET_AGENT
if([string]::IsNullOrWhiteSpace($role)){throw 'PMCRO_TARGET_AGENT is required'}
if($m.PSObject.Properties['apiVersion'] -and [string]$m.apiVersion -eq 'pmcro.message/v1'){
  foreach($field in @('messageId','sourceAgent','targetAgent','trailId','evidenceStatus','payload')){if(-not $m.PSObject.Properties[$field]){throw "missing queue field: $field"}}
  if([string]$m.targetAgent -ne 'csuite-agent'){throw 'queue targetAgent must be csuite-agent'}
  if(-not $m.payload.PSObject.Properties['executiveAgent'] -or [string]$m.payload.executiveAgent -ne $role){throw 'payload.executiveAgent does not match this executive role'}
  if(-not $m.payload.PSObject.Properties['seed'] -or [string]::IsNullOrWhiteSpace([string]$m.payload.seed)){throw 'payload.seed missing'}
  $messageId=[string]$m.messageId;$seed=[string]$m.payload.seed;$source=[string]$m.sourceAgent;$trail=[string]$m.trailId;$status=[string]$m.evidenceStatus
}else{
  foreach($field in @('messageId','seed','sourceAgent','targetAgent','trailRef','status')){if(-not $m.PSObject.Properties[$field]-or[string]::IsNullOrWhiteSpace([string]$m.$field)){throw "missing legacy field: $field"}}
  if([string]$m.targetAgent -ne $role){throw 'legacy targetAgent does not match this executive role'}
  $messageId=[string]$m.messageId;$seed=[string]$m.seed;$source=[string]$m.sourceAgent;$trail=[string]$m.trailRef;$status=[string]$m.status
}
if($status -notin @('CONFIRMED','NOT-YET-VERIFIED','NOT-RUN')){throw 'invalid evidence status'}
$out=[ordered]@{schema='pmcro.executive.event/v1';messageKind='executive.advice';parentMessageId=$messageId;sourceAgent=$role;targetAgent='csuite-agent';parentTrailRef=$trail;evidenceStatus='NOT-YET-VERIFIED';seed=$seed;recommendation='Review within this executive scope; delegate external execution only through a registered domain agent/capability and explicit grant.';delegations=@();governanceAuditRefs=@();externalSideEffectExecuted=$false;queueReady=$true;nextMessageKinds=@('executive.decision','executive.delegation','executive.escalation')}
$json=$out|ConvertTo-Json -Depth 12
if($OutputPath){[IO.File]::WriteAllText($OutputPath,$json+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))}else{Write-Output $json}
return
