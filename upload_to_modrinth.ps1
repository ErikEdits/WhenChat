# Uploads every WhenChat release JAR to Modrinth as a separate Modrinth version.
#
# Per (MC version + loader) combination produces ONE Modrinth version, with:
#   - The correct loader(s) flag (Fabric jar is also marked as Quilt-compatible
#     because Quilt Loader runs Fabric mods natively)
#   - The correct Minecraft version
#   - Fabric API as a required dependency for Fabric/Quilt uploads
#
# Idempotent: existing Modrinth versions are skipped, so this is safe to re-run
# after adding new MC versions or loaders.
#
# Usage:
#   $env:MODRINTH_TOKEN = "mrp_yourTokenHere"
#   .\upload_to_modrinth.ps1
#
# Required PAT scopes:
#   - Read projects
#   - Create versions
#   - Write projects (optional, only needed to auto-set project to client-side only)

$ErrorActionPreference = "Stop"

if (-not $env:MODRINTH_TOKEN) {
    Write-Error "MODRINTH_TOKEN env var not set. Run: `$env:MODRINTH_TOKEN = 'mrp_...'"
    exit 1
}

$token       = $env:MODRINTH_TOKEN
$slug        = "whenchat"
$githubRepo  = "ErikEdits/WhenChat"
$fabricApiId = "P7dR8mSH"      # fabric-api project id on Modrinth
$userAgent   = "ErikEdits/WhenChat (modrinth-uploader)"

# --- Read mod version from gradle.properties --------------------------------

$gradleProps = Join-Path $PSScriptRoot "gradle.properties"
$modVersion = (Select-String -Path $gradleProps -Pattern '^\s*mod_version\s*=\s*(.+)\s*$').Matches.Groups[1].Value.Trim()
Write-Host "Mod version: $modVersion"

# --- Versions per loader to upload ------------------------------------------
# Fabric jar is also marked as Quilt-compatible.

$fabricVersions = @(
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

$neoforgeVersions = @(
    @{ mc = "1.20.6"; neoforge = "20.6.139" },
    @{ mc = "1.21";   neoforge = "21.0.167" },
    @{ mc = "1.21.1"; neoforge = "21.1.233" },
    @{ mc = "1.21.3"; neoforge = "21.3.96"  },
    @{ mc = "1.21.4"; neoforge = "21.4.157" },
    @{ mc = "1.21.5"; neoforge = "21.5.97"  },
    @{ mc = "1.21.8"; neoforge = "21.8.53"  }
)

$forgeVersions = @(
    @{ mc = "1.20.6"; forge = "50.1.0"  },
    @{ mc = "1.21";   forge = "51.0.33" },
    @{ mc = "1.21.1"; forge = "52.0.40" },
    @{ mc = "1.21.3"; forge = "53.0.34" },
    @{ mc = "1.21.4"; forge = "54.1.6"  },
    @{ mc = "1.21.5"; forge = "55.0.22" }
)

# --- Workspace --------------------------------------------------------------

$tmpDir = Join-Path $env:TEMP "whenchat-modrinth-upload"
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
New-Item -ItemType Directory $tmpDir | Out-Null

# --- Verify token + get project id ------------------------------------------

Write-Host "Verifying token + fetching project info..."
$projectFile = Join-Path $tmpDir "project.json"
$status = & curl.exe -s -o $projectFile -w "%{http_code}" `
    -H "Authorization: $token" -H "User-Agent: $userAgent" `
    "https://api.modrinth.com/v2/project/$slug"
if ($status -ne "200") {
    Write-Error "Project fetch failed (HTTP $status). Body: $(Get-Content -Raw $projectFile)"
    exit 1
}
$project   = (Get-Content -Raw $projectFile) | ConvertFrom-Json
$projectId = $project.id
Write-Host "  Project: $($project.title)  (id: $projectId)"

# --- Force project-wide environment to client-side only ---------------------
# WhenChat only modifies how chat is rendered on the client. Mark the project
# as client_side=required, server_side=unsupported so Modrinth filters and
# the new version-level environment UI behave correctly.

if ($project.client_side -ne "required" -or $project.server_side -ne "unsupported") {
    Write-Host "  Patching project environment to client-side only..."
    $patchPayload = @{ client_side = "required"; server_side = "unsupported" } | ConvertTo-Json -Compress
    $patchFile = Join-Path $tmpDir "patch.json"
    [System.IO.File]::WriteAllText($patchFile, $patchPayload, [System.Text.UTF8Encoding]::new($false))

    $respFile = Join-Path $tmpDir "patch-resp.txt"
    $patchStatus = & curl.exe -s -o $respFile -w "%{http_code}" `
        -H "Authorization: $token" -H "User-Agent: $userAgent" `
        -H "Content-Type: application/json" `
        -X PATCH `
        --data-binary "@$patchFile" `
        "https://api.modrinth.com/v2/project/$projectId"
    if ($patchStatus -eq "204" -or $patchStatus -eq "200") {
        Write-Host "  Project environment updated: client_side=required, server_side=unsupported" -ForegroundColor Green
    } else {
        $body = if (Test-Path $respFile) { Get-Content -Raw $respFile } else { "" }
        Write-Warning "  Could not patch project environment (HTTP $patchStatus): $body"
        Write-Warning "  (Continuing - your PAT may not have 'Write projects' scope. Set client/server-side manually at https://modrinth.com/mod/$slug/settings)"
    }
} else {
    Write-Host "  Project environment already client-side only - nothing to patch"
}

# --- Fetch existing versions ------------------------------------------------

$existingFile = Join-Path $tmpDir "existing.json"
$status = & curl.exe -s -o $existingFile -w "%{http_code}" `
    -H "Authorization: $token" -H "User-Agent: $userAgent" `
    "https://api.modrinth.com/v2/project/$slug/version"
$existing = if ($status -eq "200") { (Get-Content -Raw $existingFile) | ConvertFrom-Json } else { @() }
$existingSet = @{}
foreach ($ev in $existing) { $existingSet[$ev.version_number] = $true }
Write-Host "  Found $($existing.Count) existing Modrinth version(s)"

# --- Upload helper ----------------------------------------------------------

function Upload-Version {
    param(
        [string]$LoaderTag,       # "fabric", "neoforge", "forge"
        [string[]]$LoaderArray,   # e.g. @("fabric", "quilt")
        [string]$Mc,
        [string]$JarName,
        [string]$DownloadUrl,
        [string]$Changelog,
        [bool]$RequireFabricApi
    )

    $versionNumber = "$modVersion+$LoaderTag-mc$Mc"
    Write-Host ""
    Write-Host "=== $LoaderTag MC $Mc ($versionNumber) ==="

    if ($existingSet.ContainsKey($versionNumber)) {
        Write-Host "  SKIP - already exists on Modrinth"
        return [PSCustomObject]@{ Loader = $LoaderTag; MC = $Mc; Status = "SKIP (exists)"; Url = "https://modrinth.com/mod/$slug/version/$versionNumber" }
    }

    $jarPath = Join-Path $tmpDir $JarName
    Write-Host "  Downloading $DownloadUrl"
    & curl.exe -fsSL -o $jarPath $DownloadUrl
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $jarPath)) {
        Write-Warning "  Download failed - is the GitHub release published with this loader's jar?"
        return [PSCustomObject]@{ Loader = $LoaderTag; MC = $Mc; Status = "DOWNLOAD FAIL"; Url = "" }
    }
    Write-Host "  Downloaded $((Get-Item $jarPath).Length) bytes"

    $deps = @()
    if ($RequireFabricApi) {
        $deps += @{ project_id = $fabricApiId; dependency_type = "required" }
    }

    $meta = [ordered]@{
        name           = "WhenChat $modVersion - $LoaderTag - Minecraft $Mc"
        version_number = $versionNumber
        changelog      = $Changelog
        dependencies   = $deps
        game_versions  = @($Mc)
        version_type   = "release"
        loaders        = $LoaderArray
        featured       = $false
        status         = "listed"
        # Mark this version as client-only (Modrinth's new per-version
        # environment metadata - ignored if your project predates it).
        client_side    = "required"
        server_side    = "unsupported"
        project_id     = $projectId
        file_parts     = @($JarName)
        primary_file   = $JarName
    } | ConvertTo-Json -Depth 10 -Compress

    $metaPath = Join-Path $tmpDir "meta-$LoaderTag-$Mc.json"
    [System.IO.File]::WriteAllText($metaPath, $meta, [System.Text.UTF8Encoding]::new($false))

    $respFile = Join-Path $tmpDir "resp-$LoaderTag-$Mc.txt"
    $httpCode = & curl.exe -s -o $respFile -w "%{http_code}" `
        -H "Authorization: $token" -H "User-Agent: $userAgent" `
        -X POST `
        "https://api.modrinth.com/v2/version" `
        -F "data=<$metaPath;type=application/json" `
        -F "$JarName=@$jarPath;type=application/java-archive"

    $body = if (Test-Path $respFile) { Get-Content -Raw $respFile } else { "" }
    if ($httpCode -eq "200" -or $httpCode -eq "201") {
        $created = $body | ConvertFrom-Json
        $url = "https://modrinth.com/mod/$slug/version/$($created.version_number)"
        Write-Host "  OK $url" -ForegroundColor Green
        return [PSCustomObject]@{ Loader = $LoaderTag; MC = $Mc; Status = "OK"; Url = $url }
    } else {
        Write-Warning "  HTTP $httpCode - $body"
        return [PSCustomObject]@{ Loader = $LoaderTag; MC = $Mc; Status = "HTTP $httpCode"; Url = "" }
    }
}

# --- Upload loops -----------------------------------------------------------

$results = @()

# Fabric (+ Quilt via fabric jar)
foreach ($v in $fabricVersions) {
    $changelog = @"
Release of **WhenChat $modVersion** for **Minecraft $($v.mc)** on **Fabric / Quilt**.

WhenChat prepends a ``[HH:mm:ss]`` timestamp in front of every chat message you receive. Client-side only.

Build info:
- Loader: Fabric (also loads on Quilt)
- Fabric Loader: $($v.loader)
- Yarn mappings: $($v.yarn)
- Java: 17 or newer

Source code: https://github.com/$githubRepo
"@
    $results += Upload-Version `
        -LoaderTag "fabric" `
        -LoaderArray @("fabric", "quilt") `
        -Mc $v.mc `
        -JarName "whenchat-fabric-mc$($v.mc).jar" `
        -DownloadUrl "https://github.com/$githubRepo/releases/download/v$modVersion-mc$($v.mc)/whenchat-fabric-mc$($v.mc).jar" `
        -Changelog $changelog `
        -RequireFabricApi $true
    Start-Sleep -Seconds 2
}

# NeoForge
foreach ($v in $neoforgeVersions) {
    $changelog = @"
Release of **WhenChat $modVersion** for **Minecraft $($v.mc)** on **NeoForge**.

WhenChat prepends a ``[HH:mm:ss]`` timestamp in front of every chat message you receive. Client-side only.

Build info:
- Loader: NeoForge $($v.neoforge)
- Java: 21

Source code: https://github.com/$githubRepo
"@
    $results += Upload-Version `
        -LoaderTag "neoforge" `
        -LoaderArray @("neoforge") `
        -Mc $v.mc `
        -JarName "whenchat-neoforge-mc$($v.mc).jar" `
        -DownloadUrl "https://github.com/$githubRepo/releases/download/v$modVersion-mc$($v.mc)/whenchat-neoforge-mc$($v.mc).jar" `
        -Changelog $changelog `
        -RequireFabricApi $false
    Start-Sleep -Seconds 2
}

# Forge
foreach ($v in $forgeVersions) {
    $changelog = @"
Release of **WhenChat $modVersion** for **Minecraft $($v.mc)** on **Forge**.

WhenChat prepends a ``[HH:mm:ss]`` timestamp in front of every chat message you receive. Client-side only.

Build info:
- Loader: Forge $($v.forge)
- Java: 21

Source code: https://github.com/$githubRepo
"@
    $results += Upload-Version `
        -LoaderTag "forge" `
        -LoaderArray @("forge") `
        -Mc $v.mc `
        -JarName "whenchat-forge-mc$($v.mc).jar" `
        -DownloadUrl "https://github.com/$githubRepo/releases/download/v$modVersion-mc$($v.mc)/whenchat-forge-mc$($v.mc).jar" `
        -Changelog $changelog `
        -RequireFabricApi $false
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "=========================="
Write-Host " Modrinth upload summary"
Write-Host "=========================="
$results | Format-Table -AutoSize

Remove-Item -Recurse -Force $tmpDir
Write-Host ""
Write-Host "Done. Don't forget to revoke the PAT at https://modrinth.com/settings/pats"
