# AMEST Homebrew tap

[English](README.md) | **Русский**

[MongoTui](https://github.com/AMEST/mongo-tui) — терминальный клиент для MongoDB.

## Установка

```sh
brew tap mongodb/brew
brew trust --formula mongodb/brew/mongodb-database-tools
brew install amest/tap/mongo-tui
mongo-tui
```

- Требуются macOS 14 (Sonoma) или новее, Apple Silicon или Intel и [Homebrew](https://brew.sh/).
- `amest/tap` подключается автоматически; tap зависимости MongoDB требует настройки выше.
- MongoTui собирается локально из исходников. Готовые пакеты (bottles) не публикуются.
- .NET SDK 10 (только для сборки), `mongosh` и MongoDB Database Tools (импорт/экспорт) устанавливаются автоматически.
  Runtime включён в приложение.
- На Intel первая установка может занять больше времени, если Homebrew потребуется собрать и SDK.

## SSH/TPAM

Требуется OpenSSH 8.4 или новее в `PATH` (проверка: `ssh -V`).

## Обновление

```sh
brew update
brew upgrade amest/tap/mongo-tui
```

## Удаление

```sh
brew uninstall amest/tap/mongo-tui
brew untap amest/tap
```

Пользовательские данные в `~/.mongotui` сохраняются.
