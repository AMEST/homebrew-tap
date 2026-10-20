# AMEST Homebrew tap

**English** | [Русский](README_RU.md)

[MongoTui](https://github.com/AMEST/mongo-tui) — a terminal UI client for MongoDB.

## Install

```sh
brew tap mongodb/brew
brew trust --formula mongodb/brew/mongodb-database-tools
brew install amest/tap/mongo-tui
mongo-tui
```

- Requires macOS 14 (Sonoma) or newer, Apple Silicon or Intel, and [Homebrew](https://brew.sh/).
- `amest/tap` is added automatically; MongoDB's dependency tap requires the setup above.
- MongoTui is built locally from source. No bottles are published.
- .NET SDK 10 (build only), `mongosh`, and MongoDB Database Tools (import/export) are installed automatically.
  The app includes its runtime.
- On Intel, the first install may take longer if Homebrew must build the SDK too.

## SSH/TPAM

Requires OpenSSH 8.4 or newer in `PATH` (check with `ssh -V`).

## Update

```sh
brew update
brew upgrade amest/tap/mongo-tui
```

## Uninstall

```sh
brew uninstall amest/tap/mongo-tui
brew untap amest/tap
```

User data in `~/.mongotui` is preserved.
