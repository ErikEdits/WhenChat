# WhenChat

**WhenChat** is a lightweight, client-side Fabric mod that automatically prepends a `[HH:mm:ss]` timestamp in front of every chat message you receive in Minecraft.

Ever wondered exactly when that message in chat was sent? Whether you're on a busy multiplayer server, taking screenshots for proof, or just want a quiet reference for the time of day without opening the F3 debug menu — WhenChat has you covered.

## Features

- **Automatic timestamps** — every incoming chat message is tagged with the current time in `[HH:mm:ss]` format
- **Zero configuration** — install, launch, done
- **Client-side only** — works on any server, vanilla or modded, no server-side install needed
- **Lightweight** — a single mixin, no extra dependencies, no performance impact
- **Subtle styling** — timestamps are rendered in gray so they don't distract from the actual message

## Example

Before:

> &lt;Steve&gt; hey, are you online?
> &lt;Alex&gt; sup

After:

> [18:42:07] &lt;Steve&gt; hey, are you online?
> [18:43:21] &lt;Alex&gt; sup

## Requirements

- **Minecraft 1.21.x** (Fabric)
- **Fabric Loader** 0.15.0 or newer
- **Java 21**

## Compatibility

WhenChat only modifies how incoming chat messages are displayed on your client. It does **not** send or intercept any data to or from the server, and is compatible with any server type (vanilla, Paper, Fabric, modded, etc.). No optional dependencies required.

## Source & Issues

Open source under the MIT license. Source code, issue tracker, and contributions welcome:
👉 [github.com/ErikEdits/WhenChat](https://github.com/ErikEdits/WhenChat)

---

If you enjoy the mod, consider leaving a thumbs up on Modrinth — it really helps!
