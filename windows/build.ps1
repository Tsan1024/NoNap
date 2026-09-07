param(
    [string]$Configuration = "Release",
    [string]$Version = "0.0.2",
    [string]$Output = "$PSScriptRoot/dist/win-x64"
)

$ErrorActionPreference = "Stop"
$project = Join-Path $PSScriptRoot "src/NoNap.App/NoNap.App.csproj"
$checks = Join-Path $PSScriptRoot "tests/NoNap.Checks/NoNap.Checks.csproj"

dotnet run --project $checks --configuration $Configuration
dotnet publish $project `
    --configuration $Configuration `
    --runtime win-x64 `
    --self-contained true `
    -p:Version=$Version `
    -p:PublishSingleFile=true `
    -p:DebugType=None `
    -p:DebugSymbols=false `
    --output $Output

Write-Host "Built $Output/NoNap.exe"
