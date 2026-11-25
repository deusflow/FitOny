# FitOny

Автономный трекер периодизации, гипертрофии и биометрии для связки **iPhone + Apple Watch**. Работает локально на устройствах пользователя без облачных серверов.

## Стек
- **Swift 6** (Strict Concurrency)
- **SwiftUI** + **Observation** (`@Observable`)
- **SwiftData** + **CryptoKit** (`AES.GCM`) + **LocalAuthentication** (Face ID)
- **HealthKit** + **CoreMotion** + **WatchConnectivity**
- **Swift Charts**, **WidgetKit**, **ActivityKit**, **AppIntents**

## Структура проекта
- `Packages/FitOnyCore` — общий расчётный модуль периодизации, прогрессии весов, разминки, объёма мышц и готовности (подключён к iOS и watchOS).
- `App-iOS` — приложение для iPhone (экраны разложены по фичам в `Screens/`, хранилище в `Storage/`, системные сервисы в `Services/`).
- `App-Watch` — приложение для Apple Watch Series 11 (`Sensors/`, `Screens/`).
- `Widgets` — системные расширения `Live Activity` (iPhone) и `Complications` (Apple Watch).
- `project.yml` — декларативная спецификация проекта для генерации `FitOny.xcodeproj` через `XcodeGen`.

## Проверка расчётного ядра без запуска Xcode
```bash
swift run --package-path Packages/FitOnyCore FitOnyCoreVerify
```

## Генерация проекта Xcode
При наличии установленного Xcode и `xcodegen`:
```bash
xcodegen generate
open FitOny.xcodeproj
```
В проекте настроены две схемы сборки:
- `FitOny-FreeSigning` — связка `FitOny-iOS` + `FitOny-Watch` без виджет-расширений (укладывается в лимит бесплатного Apple ID).
- `FitOny-Full` — полная сборка со всеми виджетами циферблата и `Live Activity` (для платного аккаунта Apple Developer).
