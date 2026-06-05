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

Pre-built JARs for every supported (loader × MC version) combination are attached to each [GitHub Release](https://github.com/ErikEdits/WhenChat/releases) and published on [Modrinth](https://modrinth.com/mod/whenchat).

## Building From Source

Requires **JDK 21**. The Gradle Wrapper is included, no separate Gradle install needed.

The project is laid out as one Gradle subproject per loader:

```
.
├── fabric/      ← Fabric (and Quilt) sources
├── neoforge/    ← NeoForge sources
└── forge/       ← Forge sources
```

Build the loader you need:

```bash
# Fabric
./gradlew :fabric:build

# NeoForge
./gradlew :neoforge:build

# Forge
./gradlew :forge:build
```

The output JAR lands in `<loader>/build/libs/whenchat-<loader>-<version>.jar`. Drop the one matching your loader into your Minecraft instance's `mods/` folder.

### Targeting a different Minecraft version

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

## How It Works

A mixin in `ChatHud#addMessage` (Fabric / Yarn names) or `ChatComponent#addMessage` (Forge / NeoForge / Mojang names) intercepts every incoming chat message and prepends the current timestamp. The mixin targets the two public `addMessage` overloads that exist across every supported version; a regex guard prevents double-prepending when one overload delegates to the other.

## License

[MIT](LICENSE) — © ErikEdits
