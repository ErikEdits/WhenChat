# Builds WhenChat for every supported Minecraft 1.21.x version.
#
# Each entry temporarily swaps gradle.properties to the target version,
# runs `gradlew build`, and copies the resulting jar to ./dist/.
#
# Usage:
#   .\build_all_versions.ps1
#
# Requirements:
#   - JDK 21
#   - Internet connection (Gradle wrapper downloads on first run)

$ErrorActionPreference = "Stop"

# Each entry: a Minecraft version, its matching yarn build, and loader version.
# See https://fabricmc.net/develop/ for up-to-date values.
$versions = @(
    @{ mc = "1.19";   yarn = "1.19+build.4";    loader = "0.14.21" },
    @{ mc = "1.19.1"; yarn = "1.19.1+build.6";  loader = "0.14.21" },
    @{ mc = "1.19.2"; yarn = "1.19.2+build.28"; loader = "0.14.21" },
    @{ mc = "1.19.3"; yarn = "1.19.3+build.5";  loader = "0.14.21" },
    @{ mc = "1.19.4"; yarn = "1.19.4+build.2";  loader = "0.14.21" },
    @{ mc = "1.20";   yarn = "1.20+build.1";    loader = "0.16.10" },
    @{ mc = "1.20.1"; yarn = "1.20.1+build.10"; loader = "0.16.10" },
    @{ mc = "1.20.2"; yarn = "1.20.2+build.4";  loader = "0.16.10" },
    @{ mc = "1.20.3"; yarn = "1.20.3+build.1";  loader = "0.16.10" },
    @{ mc = "1.20.4"; yarn = "1.20.4+build.3";  loader = "0.16.10" },
    @{ mc = "1.20.5"; yarn = "1.20.5+build.1";  loader = "0.16.10" },
    @{ mc = "1.20.6"; yarn = "1.20.6+build.3";  loader = "0.16.10" },
    @{ mc = "1.21";   yarn = "1.21+build.9";    loader = "0.16.10" },
    @{ mc = "1.21.1"; yarn = "1.21.1+build.3";  loader = "0.16.10" },
    @{ mc = "1.21.2"; yarn = "1.21.2+build.1";  loader = "0.16.10" },
    @{ mc = "1.21.3"; yarn = "1.21.3+build.2";  loader = "0.16.10" },
    @{ mc = "1.21.4"; yarn = "1.21.4+build.8";  loader = "0.16.10" },
    @{ mc = "1.21.5"; yarn = "1.21.5+build.1";  loader = "0.16.14" },
    @{ mc = "1.21.6"; yarn = "1.21.6+build.1";  loader = "0.16.14" },
    @{ mc = "1.21.7"; yarn = "1.21.7+build.8";  loader = "0.16.14" },
    @{ mc = "1.21.8";  yarn = "1.21.8+build.1";  loader = "0.17.2" },
    @{ mc = "1.21.9";  yarn = "1.21.9+build.1";  loader = "0.17.2" },
    @{ mc = "1.21.10"; yarn = "1.21.10+build.3"; loader = "0.19.3" },
    @{ mc = "1.21.11"; yarn = "1.21.11+build.6"; loader = "0.19.3" }
)

$repoRoot = $PSScriptRoot
$propsPath = Join-Path $repoRoot "gradle.properties"
$distDir = Join-Path $repoRoot "dist"
$libsDir = Join-Path $repoRoot "build\libs"

# Backup original gradle.properties so we can restore it at the end.
$backupPath = "$propsPath.bak"
Copy-Item $propsPath $backupPath -Force

# Ensure dist folder exists and is empty.
if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force }
New-Item -ItemType Directory -Path $distDir | Out-Null

$gradleCmd = Join-Path $repoRoot "gradlew.bat"

$results = @()

try {
    foreach ($v in $versions) {
        $mc = $v.mc
        $yarn = $v.yarn
        $loader = $v.loader

        Write-Host ""
        Write-Host "============================================================"
        Write-Host " Building WhenChat for Minecraft $mc"
        Write-Host "============================================================"

        # Patch gradle.properties for this target.
        $content = Get-Content $backupPath -Raw
        $content = $content -replace '(?m)^minecraft_version\s*=.*$',  "minecraft_version = $mc"
        $content = $content -replace '(?m)^yarn_mappings\s*=.*$',      "yarn_mappings = $yarn"
        $content = $content -replace '(?m)^loader_version\s*=.*$',     "loader_version = $loader"
        Set-Content -Path $propsPath -Value $content -NoNewline

        # Clean previous build output for this iteration.
        if (Test-Path $libsDir) { Remove-Item $libsDir -Recurse -Force }

        # Run gradle build.
        & $gradleCmd build --no-daemon
        if ($LASTEXITCODE -ne 0) {
            $results += [PSCustomObject]@{ Version = $mc; Status = "FAILED" }
            Write-Warning "Build failed for $mc - continuing with next version."
            continue
        }

        # Copy the produced jar to dist/ with the MC version in the filename.
        $jars = Get-ChildItem -Path $libsDir -Filter "whenchat-*.jar" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch '-sources\.jar$' }
        if ($jars.Count -eq 0) {
            $results += [PSCustomObject]@{ Version = $mc; Status = "NO JAR" }
            continue
        }
        foreach ($jar in $jars) {
            $newName = "whenchat-$mc-$($jar.BaseName.Split('-')[1]).jar"
            # Fallback: use a simple name pattern.
            $modVersion = (Select-String -Path $propsPath -Pattern '^mod_version\s*=\s*(.+)$').Matches.Groups[1].Value.Trim()
            $newName = "whenchat-$modVersion-mc$mc.jar"
            Copy-Item $jar.FullName (Join-Path $distDir $newName) -Force
        }

        $results += [PSCustomObject]@{ Version = $mc; Status = "OK" }
    }
}
finally {
    # Restore original gradle.properties.
    Copy-Item $backupPath $propsPath -Force
    Remove-Item $backupPath -Force
}

Write-Host ""
Write-Host "============================================================"
Write-Host " Build summary"
Write-Host "============================================================"
$results | Format-Table -AutoSize

Write-Host ""
Write-Host "Output jars are in: $distDir"
