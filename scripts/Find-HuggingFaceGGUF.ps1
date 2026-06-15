[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Query,

    [string]$Author = '',
    [int]$MaxResults = 10,
    [string]$Repository = ''
)

$ErrorActionPreference = 'Stop'

function Get-RequestHeaders {
    return @{ 'User-Agent' = 'llama-vscode-local/1.0' }
}

function Search-GgufRepositories {
    param(
        [string]$SearchQuery,
        [string]$Publisher,
        [int]$Limit
    )

    $authorPart = if ($Publisher) { '&author=' + [uri]::EscapeDataString($Publisher) } else { '' }
    $url = "https://huggingface.co/api/models?search=$([uri]::EscapeDataString($SearchQuery))&filter=gguf$authorPart&limit=$Limit"

    Invoke-RestMethod -Uri $url -Headers (Get-RequestHeaders)
}

function Get-RepositoryGgufFiles {
    param(
        [string]$Repo
    )

    $url = "https://huggingface.co/api/models/$Repo"
    $meta = Invoke-RestMethod -Uri $url -Headers (Get-RequestHeaders)

    $meta.siblings |
    Where-Object { $_.rfilename -like '*.gguf' } |
    Select-Object @{ Name = 'file'; Expression = { $_.rfilename } }
}

if ($Repository) {
    Write-Host ('GGUF files in ' + $Repository + ':') -ForegroundColor Cyan
    Get-RepositoryGgufFiles -Repo $Repository | Format-Table -AutoSize
    exit 0
}

Write-Host "Searching Hugging Face GGUF repositories..." -ForegroundColor Cyan
$results = Search-GgufRepositories -SearchQuery $Query -Publisher $Author -Limit $MaxResults

if (-not $results) {
    Write-Host 'No matching repositories found.' -ForegroundColor Yellow
    exit 0
}

$rows = $results |
Select-Object @{ Name = 'repo'; Expression = { $_.id } },
@{ Name = 'downloads'; Expression = { $_.downloads } },
@{ Name = 'likes'; Expression = { $_.likes } }

$rows | Sort-Object downloads -Descending | Format-Table -AutoSize

Write-Host ''
Write-Host 'Tip: Use -Repository <owner/repo> to list GGUF files for one result.' -ForegroundColor DarkGray
