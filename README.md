# WhenChat

A lightweight client-side mod that prepends a `[HH:mm:ss]` timestamp in front of every chat message you receive in Minecraft.

Never lose track of when a message was sent again — perfect for busy servers, screenshots, or just keeping an eye on the time without opening the F3 menu. Works automatically with no configuration required.

## Supported Loaders and Versions

| Loader        | Minecraft versions                                |
| ------------- | ------------------------------------------------- |
| **Fabric**    | 1.19, 1.19.1 – 1.19.4, 1.20 – 1.20.6, 1.21 – 1.21.11 (24 versions) |
| **Quilt**     | Same as Fabric — Quilt Loader runs the Fabric JAR natively |
| **NeoForge**  | 1.20.6, 1.21, 1.21.1, 1.21.3, 1.21.4, 1.21.5, 1.21.8 |
| **Forge**     | 1.20.6, 1.21, 1.21.1, 1.21.3, 1.21.4, 1.21.5      |

Pre-built JARs for every supported (loader × MC version) are attached to each GitHub Release and published to Modrinth.

## Building From Source

Requires **JDK 21**. The Gradle Wrapper is included, no separate Gradle install needed.

The project is laid out as one Gradle subproject per loader:

```
.
├── fabric/      ← Fabric (and Quilt) sources
├── neoforge/    ← NeoForge sources
└── forge/       ← Forge sources
```

### Build one loader

```bash
# Fabric
./gradlew :fabric:build

# NeoForge
./gradlew :neoforge:build

# Forge
./gradlew :forge:build
```

The output JARs land in `<loader>/build/libs/whenchat-<loader>-<version>.jar`. Drop the one matching your loader into your Minecraft instance's `mods/` folder.

### Target a different Minecraft version

`gradle.properties` at the repo root defaults to MC 1.21.1. Edit these values and rebuild:

```properties
minecraft_version = 1.21.4
# Fabric (only)
yarn_mappings = 1.21.4+build.8
loader_version = 0.16.10
# Forge (only)
forge_version = 54.1.6
# NeoForge (only)
neoforge_version = 21.4.157
```

Only the values relevant to the loader you are building need to be correct.

## Automated CI Builds

Every push to `main` runs the full matrix on GitHub Actions:

- 24 Fabric jobs
- 7 NeoForge jobs
- 6 Forge jobs

= **37 builds** per push. Artifacts are attached to each workflow run so they can be downloaded individually.

### Tagged releases

Pushing a `v*` tag produces one GitHub Release per Minecraft version with all matching loader JARs attached:

```bash
git tag v1.0.3
git push origin v1.0.3
```

For example, the `v1.0.3-mc1.21.1` release ships `whenchat-fabric-mc1.21.1.jar`, `whenchat-neoforge-mc1.21.1.jar` and `whenchat-forge-mc1.21.1.jar` as assets.

## Publishing to Modrinth

`upload_to_modrinth.ps1` uploads every GitHub-released JAR to Modrinth as a separate version, with the correct `loaders` flag (Fabric jar is also marked as Quilt-compatible) and Fabric API set as a required dependency for Fabric/Quilt uploads.

```powershell
$env:MODRINTH_TOKEN = "mrp_yourTokenHere"
.\upload_to_modrinth.ps1
```

The script is idempotent: existing Modrinth versions are skipped, so it is safe to re-run after adding new MC versions or bumping the mod version.

## Tests

The timestamp-formatting logic lives in `TimestampPrefix` — a pure helper extracted from the mixin so it can be unit-tested without bringing the Minecraft / Mixin runtime onto the test classpath.

Run the test suite locally:

```bash
./gradlew :fabric:test
```

The CI matrix runs these tests on every supported Minecraft version, so any regression is caught against all targets in one push.

## How It Works

A mixin in `ChatHud#addMessage` (Fabric / Yarn names) or `ChatComponent#addMessage` (Forge / NeoForge / Mojang names) intercepts every incoming chat message and prepends the current timestamp. The mixin targets the two public `addMessage` overloads that exist across every supported version; a regex guard in the wrap method prevents double-prepending when one overload delegates to the other.

## License

[MIT](LICENSE) — © ErikEdits
