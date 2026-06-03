# WhenChat

A lightweight Fabric client-side mod that prepends a `[HH:mm:ss]` timestamp in front of every chat message you receive in Minecraft.

Never lose track of when a message was sent again — perfect for busy servers, screenshots, or just keeping an eye on the time without opening the F3 menu. Works automatically with no configuration required.

## Supported Versions

Builds are produced for every **Minecraft 1.21.x** release (1.21 through 1.21.11). One jar per MC version.

| MC version | Yarn build       | Loader  |
| ---------- | ---------------- | ------- |
| 1.21       | 1.21+build.9     | 0.16.10 |
| 1.21.1     | 1.21.1+build.3   | 0.16.10 |
| 1.21.2     | 1.21.2+build.1   | 0.16.10 |
| 1.21.3     | 1.21.3+build.2   | 0.16.10 |
| 1.21.4     | 1.21.4+build.8   | 0.16.10 |
| 1.21.5     | 1.21.5+build.1   | 0.16.14 |
| 1.21.6     | 1.21.6+build.1   | 0.16.14 |
| 1.21.7     | 1.21.7+build.8   | 0.16.14 |
| 1.21.8     | 1.21.8+build.1   | 0.17.2  |
| 1.21.9     | 1.21.9+build.1   | 0.17.2  |
| 1.21.10    | 1.21.10+build.3  | 0.19.3  |
| 1.21.11    | 1.21.11+build.6  | 0.19.3  |

Requires **JDK 21** to build.

## Build for a Single Version

The committed `gradle.properties` defaults to **MC 1.21.1**. Run:

```bash
# Windows (PowerShell or CMD)
.\gradlew.bat build

# macOS / Linux
./gradlew build
```

The resulting `.jar` is at `build/libs/whenchat-1.0.0.jar`. Drop it into your Minecraft instance's `mods/` folder.

To target a different 1.21.x version, edit the three values at the top of `gradle.properties` (see the table above) and rebuild.

## Build for All 1.21.x Versions at Once

Run the bundled PowerShell script:

```powershell
.\build_all_versions.ps1
```

It loops through every supported MC version, builds each, and copies all jars to `./dist/` named like `whenchat-1.0.0-mc1.21.4.jar`.

The script restores `gradle.properties` to its original state after running.

## Automated CI Builds

Every push to `main` triggers a GitHub Actions matrix build for all 1.21.x versions. Artifacts are attached to each workflow run.

Pushing a tag of the form `v1.0.0` triggers a **separate GitHub Release per Minecraft version**, each with its own JAR attached:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This produces releases like:

- `v1.0.0-mc1.21` — JAR for Minecraft 1.21
- `v1.0.0-mc1.21.1` — JAR for Minecraft 1.21.1
- ...
- `v1.0.0-mc1.21.8` — JAR for Minecraft 1.21.8

## How It Works

A mixin in `net.minecraft.client.gui.hud.ChatHud#addMessage` intercepts every incoming message and prepends the current timestamp. Two mixin targets are registered so different 1.21.x builds work without code changes (`require = 0` lets non-matching signatures silently no-op).

## License

[MIT](LICENSE) — © ErikEdits
