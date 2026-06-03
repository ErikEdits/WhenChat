# Uploads every WhenChat GitHub release JAR to Modrinth as a separate Modrinth
# version, each tied to exactly one Minecraft version and depending on Fabric API.
#
# Idempotent: fetches existing Modrinth versions first and skips anything that
# is already uploaded. Safe to re-run after adding new MC versions or bumping
# the mod version.
#
# Usage:
#   $env:MODRINTH_TOKEN = "mrp_yourTokenHere"
#   .\upload_to_modrinth.ps1
#
# Required PAT scopes: Read projects + Create versions.
# Cleanup afterwards:
#   Remove-Item Env:MODRINTH_TOKEN
#   (and delete the PAT at https://modrinth.com/settings/pats)

$ErrorActionPreference = "Stop"

if (-not $env:MODRINTH_TOKEN) {
    Write-Error "MODRINTH_TOKEN env var not set. Run: `$env:MODRINTH_TOKEN = 'mrp_...'"
    exit 1
}

$token       = $env:MODRINTH_TOKEN
$slug        = "whenchat"
$githubRepo  = "ErikEdits/WhenChat"
$fabricApiId = "P7dR8mSH"      # fabric-api project id on Modrinth (well-known)
$userAgent   = "ErikEdits/WhenChat (modrinth-uploader)"

# --- Read mod version from gradle.properties --------------------------------

$gradleProps = Join-Path $PSScriptRoot "gradle.properties"
if (-not (Test-Path $gradleProps)) {
    Write-Error "Cannot find gradle.properties next to this script."
    exit 1
}
$modVersion = (Select-String -Path $gradleProps -Pattern '^\s*mod_version\s*=\s*(.+)\s*$').Matches.Groups[1].Value.Trim()
if (-not $modVersion) {
    Write-Error "mod_version not found in gradle.properties."
    exit 1
}
Write-Host "Mod version (from gradle.properties): $modVersion"

# --- Versions to upload -----------------------------------------------------
# When you add a new MC version, just add a row here and re-run. Already-
# uploaded versions are skipped automatically.

$versions = @(
    @{ mc = "1.19";    loader = "0.14.21"; yarn = "1.19+build.4"    },
    @{ mc = "1.19.1";  loader = "0.14.21"; yarn = "1.19.1+build.6"  },
    @{ mc = "1.19.2";  loader = "0.14.21"; yarn = "1.19.2+build.28" },
    @{ mc = "1.19.3";  loader = "0.14.21"; yarn = "1.19.3+build.5"  },
    @{ mc = "1.19.4";  loader = "0.14.21"; yarn = "1.19.4+build.2"  },
    @{ mc = "1.20";    loader = "0.16.10"; yarn = "1.20+build.1"    },
    @{ mc = "1.20.1";  loader = "0.16.10"; yarn = "1.20.1+build.10" },
    @{ mc = "1.20.2";  loader = "0.16.10"; yarn = "1.20.2+build.4"  },
    @{ mc = "1.20.3";  loader = "0.16.10"; yarn = "1.20.3+build.1"  },
    @{ mc = "1.20.4";  loader = "0.16.10"; yarn = "1.20.4+build.3"  },
    @{ mc = "1.20.5";  loader = "0.16.10"; yarn = "1.20.5+build.1"  },
    @{ mc = "1.20.6";  loader = "0.16.10"; yarn = "1.20.6+build.3"  },
    @{ mc = "1.21";    loader = "0.16.10"; yarn = "1.21+build.9"    },
    @{ mc = "1.21.1";  loader = "0.16.10"; yarn = "1.21.1+build.3"  },
    @{ mc = "1.21.2";  loader = "0.16.10"; yarn = "1.21.2+build.1"  },
    @{ mc = "1.21.3";  loader = "0.16.10"; yarn = "1.21.3+build.2"  },
    @{ mc = "1.21.4";  loader = "0.16.10"; yarn = "1.21.4+build.8"  },
    @{ mc = "1.21.5";  loader = "0.16.14"; yarn = "1.21.5+build.1"  },
    @{ mc = "1.21.6";  loader = "0.16.14"; yarn = "1.21.6+build.1"  },
    @{ mc = "1.21.7";  loader = "0.16.14"; yarn = "1.21.7+build.8"  },
    @{ mc = "1.21.8";  loader = "0.17.2";  yarn = "1.21.8+build.1"  },
    @{ mc = "1.21.9";  loader = "0.17.2";  yarn = "1.21.9+build.1"  },
    @{ mc = "1.21.10"; loader = "0.19.3";  yarn = "1.21.10+build.3" },
    @{ mc = "1.21.11"; loader = "0.19.3";  yarn = "1.21.11+build.6" }
)

# --- Workspace --------------------------------------------------------------

$tmpDir = Join-Path $env:TEMP "whenchat-modrinth-upload"
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
New-Item -ItemType Directory $tmpDir | Out-Null

# --- Verify token + get project id ------------------------------------------

Write-Host "Verifying token and fetching project info..."
$projectFile = Join-Path $tmpDir "project.json"
$status = & curl.exe -s -o $projectFile -w "%{http_code}" `
    -H "Authorization: $token" `
    -H "User-Agent: $userAgent" `
    "https://api.modrinth.com/v2/project/$slug"

if ($status -ne "200") {
    Write-Error "Project fetch failed (HTTP $status). Body: $(Get-Content -Raw $projectFile)"
    exit 1
}
$project   = (Get-Content -Raw $projectFile) | ConvertFrom-Json
$projectId = $project.id
Write-Host "  Project: $($project.title)  (id: $projectId)"

# --- Fetch existing versions so we can skip duplicates ----------------------

Write-Host "Fetching existing Modrinth versions..."
$existingFile = Join-Path $tmpDir "existing.json"
$status = & curl.exe -s -o $existingFile -w "%{http_code}" `
    -H "Authorization: $token" `
    -H "User-Agent: $userAgent" `
    "https://api.modrinth.com/v2/project/$slug/version"

if ($status -ne "200") {
    Write-Error "Existing-versions fetch failed (HTTP $status). Body: $(Get-Content -Raw $existingFile)"
    exit 1
}
$existing = (Get-Content -Raw $existingFile) | ConvertFrom-Json
$existingSet = @{}
foreach ($ev in $existing) { $existingSet[$ev.version_number] = $true }
Write-Host "  Found $($existing.Count) existing version(s) on Modrinth"

# --- Upload loop ------------------------------------------------------------

$results = @()

foreach ($v in $versions) {
    $mc = $v.mc
    $versionNumber = "$modVersion+mc$mc"

    Write-Host ""
    Write-Host "=== Minecraft $mc ($versionNumber) ==="

    if ($existingSet.ContainsKey($versionNumber)) {
        Write-Host "  SKIP - already exists on Modrinth"
        $results += [PSCustomObject]@{ MC = $mc; Status = "SKIP (exists)"; Url = "https://modrinth.com/mod/$slug/version/$versionNumber" }
        continue
    }

    $jarName     = "whenchat-mc$mc.jar"
    $jarPath     = Join-Path $tmpDir $jarName
    $downloadUrl = "https://github.com/$githubRepo/releases/download/v$modVersion-mc$mc/$jarName"

    Write-Host "  Downloading $downloadUrl"
    & curl.exe -fsSL -o $jarPath $downloadUrl
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $jarPath)) {
        Write-Warning "  Download failed - is the GitHub release published?"
        $results += [PSCustomObject]@{ MC = $mc; Status = "DOWNLOAD FAIL"; Url = "" }
        continue
    }
    $jarSize = (Get-Item $jarPath).Length
    Write-Host "  Downloaded $jarSize bytes"

    $changelog = @"
Release of **WhenChat $modVersion** for **Minecraft $mc**.

WhenChat prepends a ``[HH:mm:ss]`` timestamp in front of every chat message you receive. Client-side only, no configuration required.

Build info:
- Minecraft: $mc
- Fabric Loader: $($v.loader)
- Yarn mappings: $($v.yarn)
- Java: 21

Source code and issue tracker: https://github.com/$githubRepo
"@

    $meta = [ordered]@{
        name           = "WhenChat $modVersion for Minecraft $mc"
        version_number = $versionNumber
        changelog      = $changelog
        dependencies   = @(@{ project_id = $fabricApiId; dependency_type = "required" })
        game_versions  = @($mc)
        version_type   = "release"
        loaders        = @("fabric")
        featured       = $false
        status         = "listed"
        project_id     = $projectId
        file_parts     = @($jarName)
        primary_file   = $jarName
    } | ConvertTo-Json -Depth 10 -Compress

    $metaPath = Join-Path $tmpDir "meta-$mc.json"
    [System.IO.File]::WriteAllText($metaPath, $meta, [System.Text.UTF8Encoding]::new($false))

    Write-Host "  Uploading to Modrinth..."
    $respFile = Join-Path $tmpDir "resp-$mc.txt"
    $httpCode = & curl.exe -s -o $respFile -w "%{http_code}" `
        -H "Authorization: $token" `
        -H "User-Agent: $userAgent" `
        -X POST `
        "https://api.modrinth.com/v2/version" `
        -F "data=<$metaPath;type=application/json" `
        -F "$jarName=@$jarPath;type=application/java-archive"

    $body = if (Test-Path $respFile) { Get-Content -Raw $respFile } else { "" }

    if ($httpCode -eq "200" -or $httpCode -eq "201") {
        $created = $body | ConvertFrom-Json
        $url = "https://modrinth.com/mod/$slug/version/$($created.version_number)"
        Write-Host "  OK $url" -ForegroundColor Green
        $results += [PSCustomObject]@{ MC = $mc; Status = "OK"; Url = $url }
    } else {
        Write-Warning "  HTTP $httpCode - $body"
        $results += [PSCustomObject]@{ MC = $mc; Status = "HTTP $httpCode"; Url = "" }
    }

    # Be polite to the API
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "=========================="
Write-Host " Modrinth upload summary"
Write-Host "=========================="
$results | Format-Table -AutoSize

# Cleanup
Remove-Item -Recurse -Force $tmpDir
Write-Host ""
Write-Host "Done. Don't forget to revoke the PAT at https://modrinth.com/settings/pats"
