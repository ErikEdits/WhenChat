# Chat Timestamps

Eine simple Fabric Client-Mod, die vor jeder empfangenen Chat-Nachricht einen `[HH:mm:ss]`-Zeitstempel einfügt.

## Unterstützte Versionen

Funktioniert für **Minecraft 1.21.x** mit Fabric Loader. Pro MC-Version wird ein eigenes Build gebraucht — Versionen in `gradle.properties` anpassen und neu bauen.

## Build

Voraussetzungen: **JDK 21** installiert (z. B. Temurin 21).

```bash
# Windows (PowerShell)
.\gradlew.bat build

# macOS / Linux
./gradlew build
```

Die fertige `.jar` liegt danach unter `build/libs/chat-timestamps-1.0.0.jar`. Diese in den `mods/`-Ordner deiner Minecraft-Instanz kopieren.

> Hinweis: Das Repo enthält **keinen** Gradle Wrapper. Beim ersten Mal entweder Gradle global installieren und einmal `gradle wrapper` ausführen, oder den Wrapper aus einem [Fabric Example Mod](https://github.com/FabricMC/fabric-example-mod) kopieren.

## Andere 1.21.x Version targeten

In `gradle.properties` die drei Werte ändern (Versionen siehe https://fabricmc.net/develop/):

```properties
minecraft_version = 1.21.4
yarn_mappings = 1.21.4+build.8
loader_version = 0.16.10
```

Dann neu bauen.

## Wie es funktioniert

Ein Mixin in `net.minecraft.client.gui.hud.ChatHud#addMessage` fängt jede eingehende Nachricht ab und stellt ihr den aktuellen Zeitstempel voran. Zwei Mixin-Targets sind hinterlegt, damit verschiedene 1.21.x Builds beide ohne Codeänderung funktionieren (`require = 0` lässt nicht-matchende Signaturen still scheitern).

## Lizenz

MIT
