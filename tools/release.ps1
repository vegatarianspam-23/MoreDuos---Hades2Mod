[CmdletBinding()]
param(
	[Parameter(Mandatory = $true, Position = 0)][string]$Version,
	[switch]$DryRun,
	[switch]$SkipWiki,
	[switch]$Yes,
	[string]$ImageFolder = 'images'
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'version must be Major.Minor.Patch, e.g. 1.45.320' }

if (-not $env:TCLI_AUTH_TOKEN) { $env:TCLI_AUTH_TOKEN = [Environment]::GetEnvironmentVariable('TCLI_AUTH_TOKEN', 'User') }

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Invoke-Git {
	$output = & git @args
	if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed" }
	return $output
}

$changelog_path = Join-Path $root 'CHANGELOG.md'
$toml_path = Join-Path $root 'thunderstore.toml'
$readme_path = Join-Path $root 'README.md'
$original = @{}
foreach ($path in $changelog_path, $toml_path, $readme_path) { $original[$path] = [IO.File]::ReadAllText($path, $utf8) }

function Restore-Files([string[]]$Paths) {
	foreach ($path in $Paths) { [IO.File]::WriteAllText($path, $original[$path], $utf8) }
}

$toml = $original[$toml_path]
$package = '{0}-{1}' -f [regex]::Match($toml, '(?m)^namespace\s*=\s*"([^"]+)"').Groups[1].Value, [regex]::Match($toml, '(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
$build_dir = Join-Path $root 'build'

$remote = (Invoke-Git remote get-url origin) -replace '\.git$', ''
$repo_match = [regex]::Match($remote, 'github\.com[:/]([^/]+)/([^/]+)$')
if (-not $repo_match.Success) { throw "origin is not a GitHub remote: $remote" }
$owner = $repo_match.Groups[1].Value
$repo = $repo_match.Groups[2].Value
$repo_url = "https://github.com/$owner/$repo"
$branch = Invoke-Git branch --show-current
$default_branch = (& git symbolic-ref --quiet --short refs/remotes/origin/HEAD) -replace '^origin/', ''
if (-not $default_branch) { $default_branch = 'main' }

if (-not (Get-ChildItem (Join-Path $root 'src') -File -Recurse | Select-Object -First 1)) { throw 'src/ is empty' }

$tcli = Join-Path $root 'tcli.exe'
if (-not (Test-Path $tcli)) { $tcli = (Get-Command tcli -ErrorAction Stop).Source }

if (-not $DryRun) {
	if (-not $env:TCLI_AUTH_TOKEN) { throw 'TCLI_AUTH_TOKEN is not set' }
	if (Invoke-Git status --porcelain --untracked-files=no) { throw 'commit your changes first: the release is built from, and tagged at, the working tree' }
	if (Invoke-Git tag --list $Version) { throw "tag $Version already exists" }
	Invoke-Git fetch --quiet origin $branch
	if ([int](Invoke-Git rev-list --count "HEAD..origin/$branch") -gt 0) { throw "origin/$branch has commits you do not have; pull first" }
}

$text = $original[$changelog_path]
$first = [regex]::Match($text, '(?m)^## \[(\d+\.\d+\.\d+)\]')
if (-not $first.Success) { throw 'no previous release heading in CHANGELOG.md' }
$pending = [regex]::Match($text.Substring(0, $first.Index), '(?m)^(### |- )')
if (-not $pending.Success) { throw 'no pending changes above the last release in CHANGELOG.md' }
$previous = $first.Groups[1].Value
if (-not (Invoke-Git tag --list $previous)) { throw "CHANGELOG.md's latest release $previous has no tag; an interrupted run may have left it stamped" }
if ($toml -notmatch "versionNumber = `"$([regex]::Escape($previous))`"") { throw "thunderstore.toml is not at $previous; an interrupted run may have left it stamped" }
$text = $text.Insert($pending.Index, "## [$Version] - $(Get-Date -Format 'yyyy-MM-dd')`n`n")
$link = [regex]::Match($text, "(?m)^\[$([regex]::Escape($previous))\]:")
if (-not $link.Success) { throw "no [$previous]: link at the foot of CHANGELOG.md" }
$text = $text.Insert($link.Index, "[$Version]: $repo_url/compare/$previous...$Version`n")

$notes = $text.Substring($pending.Index)
$notes = $notes.Substring($notes.IndexOf("`n") + 1)
$notes = $notes.Substring(0, [regex]::Match($notes, '(?m)^## \[').Index).Trim()

Write-Host "$package $previous -> $Version$(if ($DryRun) { '  (dry run)' })" -ForegroundColor Cyan
Write-Host $notes
Write-Host ''

if (-not $DryRun -and -not $Yes) {
	if ((Read-Host "Publish $package $Version to Thunderstore and push to $owner/$repo ($branch)? [y/N]") -notmatch '^y') { throw 'cancelled' }
}

$published = $false
try {
	[IO.File]::WriteAllText($changelog_path, $text, $utf8)
	[IO.File]::WriteAllText($toml_path, ($toml -replace 'versionNumber = ".*"', "versionNumber = `"$Version`""), $utf8)
	$image_pattern = '\]\((\./)?' + [regex]::Escape($ImageFolder) + '/'
	[IO.File]::WriteAllText($readme_path, ($original[$readme_path] -replace $image_pattern, "]($repo_url/raw/$default_branch/$ImageFolder/"), $utf8)

	if (Test-Path $build_dir) { Get-ChildItem $build_dir -Filter '*.zip' | Remove-Item -Confirm:$false }
	& $tcli build
	if ($LASTEXITCODE -ne 0) { throw 'tcli build failed' }
	$artifact = Join-Path $build_dir "$package-$Version.zip"
	if (-not (Test-Path $artifact)) { throw "expected $artifact" }

	if ($DryRun) {
		Write-Host "Built $artifact" -ForegroundColor Green
		return
	}

	& $tcli publish --file $artifact
	if ($LASTEXITCODE -ne 0) { throw 'tcli publish failed' }
	$published = $true
} finally {
	if ($published) { Restore-Files $readme_path } else { Restore-Files $changelog_path, $toml_path, $readme_path }
}

Invoke-Git add CHANGELOG.md thunderstore.toml
Invoke-Git commit --quiet --message "Release $Version"
Invoke-Git tag $Version --annotate --message "Release $Version"
Invoke-Git -c "credential.username=$owner" push --quiet origin "HEAD:$branch" "refs/tags/$Version"
Write-Host "Pushed $branch and tag $Version" -ForegroundColor Green

try {
	$start = New-Object System.Diagnostics.ProcessStartInfo('git', 'credential fill')
	$start.UseShellExecute = $false
	$start.RedirectStandardInput = $true
	$start.RedirectStandardOutput = $true
	$start.EnvironmentVariables['GIT_TERMINAL_PROMPT'] = '0'
	$start.EnvironmentVariables['GCM_INTERACTIVE'] = 'never'
	$input_encoding = [Console]::InputEncoding
	try {
		[Console]::InputEncoding = $utf8
		$process = [System.Diagnostics.Process]::Start($start)
	} finally {
		[Console]::InputEncoding = $input_encoding
	}
	$process.StandardInput.Write("protocol=https`nhost=github.com`nusername=$owner`n`n")
	$process.StandardInput.Close()
	$credential = $process.StandardOutput.ReadToEnd() -split "`n"
	$process.WaitForExit()
	$github_token = ($credential | Where-Object { $_ -like 'password=*' }) -replace '^password=', ''
	if (-not $github_token) { throw 'no stored GitHub credential' }
	$headers = @{ Authorization = "Bearer $github_token"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'release.ps1' }
	$body = @{ tag_name = $Version; name = $Version; body = $notes } | ConvertTo-Json
	$release = Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$owner/$repo/releases" -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $utf8.GetBytes($body)
	$upload = "https://uploads.github.com/repos/$owner/$repo/releases/$($release.id)/assets?name=$([IO.Path]::GetFileName($artifact))"
	Invoke-RestMethod -Method Post -Uri $upload -Headers $headers -ContentType 'application/zip' -InFile $artifact | Out-Null
	Write-Host "GitHub release $($release.html_url)" -ForegroundColor Green
} catch {
	Write-Warning "GitHub release not created ($($_.Exception.Message)). Create it by hand: $repo_url/releases/new?tag=$Version"
}

if (-not $SkipWiki) {
	try {
		& (Join-Path $PSScriptRoot 'wiki.ps1')
	} catch {
		Write-Warning "wiki not synced ($($_.Exception.Message)). Re-run tools\wiki.ps1"
	}
}

Write-Host "Released $package $Version" -ForegroundColor Green
