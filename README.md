# INTELEGENTOFF — iOS

Нативное приложение магазина [intelegent.shop](https://intelegent.shop) на SwiftUI (iOS 17+).
Визуально и функционально повторяет веб-версию (Nuxt), работает с тем же API `api.intelegent.shop`.

## Структура

```
project.yml                 — описание проекта для XcodeGen (.xcodeproj не храним)
Intelegent/
  App/                      — точка входа, вкладки, общее состояние (корзина, тема)
  Core/                     — API-клиент, модели, форматирование цен и скидок
  Design/                   — цвета тем, шрифты, базовые компоненты (кнопка, бейдж, цена…)
  Features/                 — экраны: главная, каталог, товар
  Resources/                — шрифты Montserrat, картинки баннера
.github/workflows/ios.yml   — сборка и скриншоты на облачном Mac
```

## Сборка

На Mac:

```bash
brew install xcodegen
xcodegen generate
open Intelegent.xcodeproj
```

Без Mac — каждый push в `main` собирает приложение в GitHub Actions и выкладывает
скриншоты экранов (тёмная и светлая тема) в артефакт `screenshots` у запуска.

## Режим скриншотов

Аргументы запуска открывают нужный экран сразу:

- `-uiScreen home | catalog | section | product`
- `-uiProduct <slug>` — какой товар открыть
- `-theme dark | light`

## Секреты

В репозитории нет и не должно быть ключей, сертификатов и профилей подписи —
они хранятся в GitHub Secrets. См. `.gitignore`.
