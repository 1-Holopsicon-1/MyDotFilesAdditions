# MyDotFilesAdditions (hypr-dots)

Личные поверх end-4/dots-hyprland (illogical-impulse), переносимые на другие машины.

## Структура

- `update.sh` — обновление базовых дотфейтов: бэкап `~/.config` → git pull `~/.cache/dots-hyprland` → инсталляция → реапплай кастом-модулей.
- `reapply-custom.sh` — восстанавливает интеграционные строки кастомных модулей в файлах illogical-impulse (идемпотентно, якоря с SKIP-защитой от апстрим-изменений).
- `setup-ii-custom.sh` — деплой кастом-модулей на машину: GNU stow пакета `ii-custom` + реапплай + перезагрузка шелла.
- `ii-custom/` — stow-пакет, зеркалит `$HOME`:
  - `.local/share/ii-custom/qs-modules/KeyboardLayoutOsd.qml` — OSD смены раскладки (полупрозрачный квадрат внизу экрана: код + язык, 1.5 с).
  - `.local/share/ii-custom/qs-modules/LockClock.qml` — большие часы на экране блокировки.

После stow: `~/.local/share/ii-custom/qs-modules` — симлинк в репо, значит **правки делаются прямо в репо**.

## Новая машина

```bash
git clone git@github.com:1-Holopsicon-1/MyDotFilesAdditions.git ~/hypr-dots
~/hypr-dots/update.sh        # ставит базовые доты (end-4) и восстанавливает интеграцию
~/hypr-dots/setup-ii-custom.sh
```

### Только кастом (без обновления базовых дотфейтов)

Если на машине доты end-4 уже установлены и обновлять их не нужно — достаточно:

```bash
git clone git@github.com:1-Holopsicon-1/MyDotFilesAdditions.git ~/hypr-dots
~/hypr-dots/setup-ii-custom.sh
```

Требования: `~/.config/quickshell/ii` существует (базовые доты стоят). GNU stow
установится автоматически (pacman/apt/dnf; спросит пароль sudo, если не хватает).
Если после деплоя OSD/часы не появились — один раз полный рестарт шелла: `qs kill -c ii && qs -c ii`.

## Ежедневные правки

1. Редактируешь `ii-custom/.local/share/ii-custom/qs-modules/*.qml` (в репо).
2. `touch ~/.config/quickshell/ii/shell.qml` — быстрый reload.
3. Коммить как обычно.

## Восстановление крупных кастомизаций (`restore/`)

Файлы ii с большими доработками не восстанавливаются вставкой по якорям — для них
хранится целая копия, и реапплей работает по детектору перетирания:

- `restore/Booru.qml` — доработанный провайдер поиска обоев (curl-путь запросов,
  авторизация провайдера через config.json, blacklist тегов и т.д.).
- `reapply-custom.sh` сравнивает живой файл с апстримным эталоном из клона
  (`~/.cache/dots-hyprland`):
  - живой == эталон → инсталлятор только что перезаписал → вернуть кастомную версию;
  - живой == кастомная → ок;
  - иначе → `SKIP` + предупреждение о ручном merge (живой файл никогда не перезатирается молча).
- API-ключи провайдеров храни в `~/.config/illogical-impulse/booru-creds.json`
  этот файл шеллом не перезаписывается и апдейтом не трогается. При деплое
  `setup-ii-custom.sh` сам предложит ввести ключи, если файла ещё нет. Формат:

  ```json
  {
      "<provider-id>": { "apiKey": "...", "userId": "..." }
  }
  ```
  (`config.json` не использовать для ключей: JsonAdapter шелла переписывает файл
  и сбрасывает неизвестные ему ключи.)

## Нюансы

- Интеграция состоит из тонких вставок в `panelFamilies/IllogicalImpulseFamily.qml`
  и `modules/ii/lock/LockSurface.qml` — их апдейтер затирает, `reapply-custom.sh`
  возвращает (update.sh делает это автоматически).
- quickshell не принимает абсолютный путь в QML-импорте — только `file:` URL.
- После изменения самой симлинк-раскладки (миграции) нужен полный рестарт шелла:
  `qs kill -c ii && qs -c ii` — reload кеш движка пересматривает не всегда.
- Позиция кастомных элементов задаётся в самих модулях (KeyboardLayoutOsd — блок
  `anchors` у `osdSquare`; LockClock — `anchors.centerIn` в корне компонента).
