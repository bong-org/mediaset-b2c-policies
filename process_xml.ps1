# Definizione dei parametri
param (
    [string]$environment,
    [string]$jsonConfigPath,
    [string]$inputFolder,
    [string]$outputFolder,
    [string]$outputBaseFolder = './Config'
)

# Determina la cartella di output basata sull'ambiente
$outputFolder = Join-Path -Path $outputBaseFolder -ChildPath $environment

# Crea la cartella di output se non esiste
if (-Not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force
}

# Leggi il file JSON con le configurazioni degli ambienti
$configs = Get-Content -Path $jsonConfigPath | ConvertFrom-Json
$replacements = $configs.$environment

# Converti PSCustomObject in Hashtable
$replacementHashtable = @{}
$replacements.psobject.Properties | ForEach-Object {
    $replacementHashtable[$_.Name] = $_.Value
}

# Funzione per sostituire i placeholder nei file XML
function Replace-Placeholders {
    param (
        [string]$content,
        [hashtable]$replacements
    )

    foreach ($key in $replacements.Keys) {
        $content = $content -replace "{{ $key }}", $replacements[$key]
    }
    return $content
}

# Processa ogni file XML nella cartella di input
Get-ChildItem -Path $inputFolder -Filter *.xml | ForEach-Object {
    $content = Get-Content -Path $_.FullName -Raw
    $updatedContent = Replace-Placeholders -content $content -replacements $replacementHashtable
    $outputPath = Join-Path -Path $outputFolder -ChildPath $_.Name
    Set-Content -Path $outputPath -Value $updatedContent
}

