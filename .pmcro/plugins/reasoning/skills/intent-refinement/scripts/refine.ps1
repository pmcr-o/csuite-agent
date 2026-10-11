param([Parameter(Mandatory=$true)][string]$RawFile,[Parameter(Mandatory=$true)][string]$RootIntentRef,[Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
python (Join-Path $PSScriptRoot 'operate.py') refine --raw-file $RawFile --root-intent-ref $RootIntentRef --output $Output
exit $LASTEXITCODE
