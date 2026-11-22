[CmdletBinding()]
param(
	[switch]$DryRun,
	[switch]$Prune
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$toml = [IO.File]::ReadAllText((Join-Path $root 'thunderstore.toml'), $utf8)
$namespace = [regex]::Match($toml, '(?m)^namespace\s*=\s*"([^"]+)"').Groups[1].Value
$name = [regex]::Match($toml, '(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
$host_url = [regex]::Match($toml, '(?m)^repository\s*=\s*"([^"]+)"').Groups[1].Value.TrimEnd('/')
if (-not $namespace -or -not $name -or -not $host_url) { throw 'thunderstore.toml is missing namespace, name or repository' }

$wiki_url = "$host_url/api/experimental/package/$namespace/$name/wiki/"
$session = $env:THUNDERSTORE_SESSION
if (-not $session) { $session = [Environment]::GetEnvironmentVariable('THUNDERSTORE_SESSION', 'User') }
if (-not $DryRun -and -not $session) { throw 'THUNDERSTORE_SESSION is not set (wiki edits need your thunderstore.io sessionid cookie; service account tokens are refused)' }

function Invoke-Api([string]$Method, [string]$Url, $Body) {
	$client = New-Object System.Net.WebClient
	$client.Headers['Accept'] = 'application/json'
	if ($Method -ne 'GET') {
		$client.Headers['Authorization'] = "Session $session"
		$client.Headers['Content-Type'] = 'application/json'
	}
	try {
		if ($Method -eq 'GET') {
			$bytes = $client.DownloadData($Url)
		} else {
			$bytes = $client.UploadData($Url, $Method, $utf8.GetBytes(($Body | ConvertTo-Json -Compress)))
		}
	} catch [System.Net.WebException] {
		$response = $_.Exception.Response
		if ($null -eq $response) { throw }
		$status = [int]$response.StatusCode
		if ($Method -eq 'GET' -and $status -eq 404) { return $null }
		$detail = (New-Object IO.StreamReader($response.GetResponseStream(), $utf8)).ReadToEnd()
		throw "$Method $Url failed with HTTP $status $detail"
	} finally {
		$client.Dispose()
	}
	$text = $utf8.GetString($bytes)
	if ($text) { return $text | ConvertFrom-Json }
}

function Format-Page([string]$Text) {
	return ($Text -replace "`r`n", "`n").Trim()
}

$live = @{}
$wiki = Invoke-Api 'GET' $wiki_url
if ($wiki) { foreach ($page in $wiki.pages) { $live[$page.title.ToLowerInvariant()] = $page } }

$files = Get-ChildItem (Join-Path $root 'wiki') -Filter '*.md' | Sort-Object Name
if (-not $files) { throw 'no pages in wiki/' }

$seen = @{}
$changed = 0
foreach ($file in $files) {
	$content = Format-Page ([IO.File]::ReadAllText($file.FullName, $utf8))
	$heading = [regex]::Match($content, '(?m)^# +(.+?)\s*$')
	if (-not $heading.Success) { throw "$($file.Name) has no '# Title' heading" }
	$title = $heading.Groups[1].Value
	$key = $title.ToLowerInvariant()
	if ($seen.ContainsKey($key)) { throw "two wiki files share the title '$title'" }
	$seen[$key] = $true

	$body = @{ title = $title; markdown_content = $content }
	$page = $live[$key]
	if ($page) {
		$current = Invoke-Api 'GET' "$host_url/api/experimental/wiki/page/$($page.id)/"
		if ((Format-Page $current.markdown_content) -ceq $content) {
			Write-Host "  unchanged  $title"
			continue
		}
		$body.id = $page.id
		$action = 'update'
	} else {
		$action = 'create'
	}
	$changed++
	if ($DryRun) {
		Write-Host "  would $action  $title" -ForegroundColor Yellow
	} else {
		Invoke-Api 'POST' $wiki_url $body | Out-Null
		Write-Host "  ${action}d  $title" -ForegroundColor Green
	}
}

foreach ($key in $live.Keys) {
	if ($seen.ContainsKey($key)) { continue }
	$page = $live[$key]
	if (-not $Prune) {
		Write-Host "  live only  $($page.title)  (-Prune deletes it)" -ForegroundColor DarkYellow
	} elseif ($DryRun) {
		Write-Host "  would delete  $($page.title)" -ForegroundColor Yellow
	} else {
		Invoke-Api 'DELETE' $wiki_url @{ id = $page.id } | Out-Null
		Write-Host "  deleted  $($page.title)" -ForegroundColor Green
	}
}

Write-Host "$namespace/$name wiki: $changed of $($files.Count) pages $(if ($DryRun) { 'differ' } else { 'pushed' })"
