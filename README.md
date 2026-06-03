# WhenChat

A lightweight Fabric client-side mod that prepends a `[HH:mm:ss]` timestamp in front of every chat message you receive in Minecraft.

Never lose track of when a message was sent again — perfect for busy servers, screenshots, or just keeping an eye on the time without opening the F3 menu. Works automatically with no configuration required.

## Supported Versions

Works on **Minecraft 1.21.x** with Fabric Loader. Each MC version needs its own build — adjust the versions in `gradle.properties` and rebuild.

## Build

Requirements: **JDK 21** installed (e.g. Temurin 21).

```bash
# Windows (PowerShell)
.\gradlew.bat build

# macOS / Linux
./gradlew build
```

The resulting `.jar` will be at `build/libs/whenchat-1.0.0.jar`. Drop it into your Minecraft instance's `mods/` folder.

> Note: this repo does **not** ship a Gradle Wrapper. First time, either install Gradle globally and run `gradle wrapper` once, or copy the wrapper files from a [Fabric Example Mod](https://github.com/FabricMC/fabric-example-mod).

## Targeting Another 1.21.x Version

Edit the three values in `gradle.properties` (check matching versions at https://fabricmc.net/develop/):

```properties
minecraft_version = 1.21.4
yarn_mappings = 1.21.4+build.8
loader_version = 0.16.10
```

Then rebuild.

## How It Works

A mixin in `net.minecraft.client.gui.hud.ChatHud#addMessage` intercepts every incoming message and prepends the current timestamp. Two mixin targets are registered so different 1.21.x builds work without code changes (`require = 0` lets non-matching signatures silently no-op).

## License

[MIT](LICENSE) — © ErikEdits
