# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

Нативное приложение SwiftUI для передачи файлов по USB между Android и Mac с Apple Silicon. Минимальный интерфейс в стиле Finder, системный акцентный цвет, нативный поиск и Liquid Glass. Устанавливается отдельно от Google Android File Transfer.

## Требования и установка

Нужны **Apple Silicon / arm64 и macOS 14.0 или новее**. Проверено на macOS 27.2 и Galaxy Z Fold7; macOS 28, Intel и другие устройства не проверены. После сборки запустите `dist/MacAndFiles.app` либо распакуйте ZIP и поместите приложение в Программы. libmtp/libusb включены; Homebrew и Android Studio для запуска не нужны. Это сборка разработки с ad-hoc-подписью, без Developer ID и нотариального заверения Apple.

## Подключение и работа

Подключите кабелем USB для данных, разблокируйте Android и выберите «Передача файлов / Android Auto». Закройте Android File Transfer, его Agent и другие MTP-приложения. Найдите устройства, выберите одно и подключитесь. Отладка USB и ADB не нужны. Двойной щелчок открывает папки; ⌘D сохраняет на Mac, ⌘U отправляет на Android; можно перетаскивать файлы Finder. ⌘↑ поднимается выше, ⌘⇧N создаёт папку, ⌘R обновляет. ⌘F ищет имена только в текущей папке; очистка или Esc возвращает список. Скрытые поиском элементы снимаются с выбора. Ещё содержит справку, отключение и диагностику. Проверяйте имена перед отправкой журналов.

## Языки

Следует предпочитаемому языку macOS и языку приложения в Системных настройках → Основные → Язык и регион. После изменения перезапустите. Включены 13 языков; остальные используют английский. Даты, размеры и проценты зависят от региона. Имена файлов и устройств сохраняются; диагностика библиотек может остаться английской.

## Поведение передачи

Совпадение имён останавливает операцию без перезаписи. Загрузки на Mac записываются временно, проверяются по размеру и перемещаются к конечному имени; отправка проверяет размер Android. Отмена или ошибка сохраняет завершённое и может оставить неполные файлы на Android. Папки копируются рекурсивно до глубины 128; символические ссылки и специальные файлы запрещены. Прогресс учитывает файлы и байты всей операции. Доступно только содержимое MTP; удаление, переименование и том Finder не реализованы.

## Сборка и проверка

Нужны Swift 6.2+, SDK macOS 26+, libmtp 1.1.23 и libusb 1.0.30. Скрипт проверяет версии и SHA-256 исходников, включает динамические библиотеки с исходниками. Архив исключает сборки и частную диагностику. Команды ниже — диагностика только для чтения, не универсальная файловая CLI или MCP. `--verify-transfer` записывает UUID-тестовые файлы: отключите GUI, используйте только разрешённое тестовое устройство и проверьте остатки.

```sh
brew install pkg-config
scripts/test.sh
scripts/test-localization.sh
scripts/test-cli.sh
scripts/test-progress.sh
scripts/build-app.sh
scripts/package-source.sh
```

```sh
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --diagnose
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --probe
```

## Лицензии и участие

Код, скрипты и документация: **MIT**. Робот Android: **CC BY 3.0**. libmtp/libusb: **LGPL-2.1-or-later**. Сохраняйте лицензии и уведомления. Android — марка Google LLC; приложение неофициальное. MacAndFiles — имя разработки: проверьте брендинг и заверение Apple перед публикацией. Полная техническая справка находится в английском README. Для участия прочитайте AGENT.md. Этот процесс ещё не публиковал проект на GitHub.

[English reference](../../README.md) · [Validation](../../VALIDATION.md) · [LICENSE](../../LICENSE) · [Third-party notices](../../THIRD_PARTY_NOTICES.md) · [AGENT.md](../../AGENT.md) · [Release guide](../RELEASING.md) · [Localization guide](../LOCALIZATION.md)

## Терминал и агенты

После установки приложения установите `maf` через `scripts/install-cli.sh`. Узнайте ID командами `maf devices` и `maf storages --device "ID"`. Список файлов, загрузка в обе стороны и создание папок описаны в `maf help` и [руководстве CLI](../CLI.md). Результат — JSON; при ошибке возвращаются код ошибки и ненулевой статус завершения. Перед работой с CLI отключите устройство в интерфейсе.

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

Сборка для macOS 14+. Проверено на macOS 27.2; старые версии ещё требуют проверки на устройствах. Liquid Glass с macOS 26.

Всего и завершено файлов, общий прогресс, средняя скорость и оценка оставшегося времени. При остановке завершённые файлы сохраняются.

Установите maf через Ещё → Терминал и агенты. При необходимости добавьте ~/.local/bin в PATH. Перед CLI-операциями отключите GUI.

maf использует тот же движок: JSON, стабильные коды ошибок и понятный статус USB для скриптов и агентов.

[MacAndFiles](https://kimtoma.github.io/MacAndFiles/ru/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
