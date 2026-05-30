# FamilyApp

An iPad-first SwiftUI application. This directory contains a clean, modern
project scaffold using **MVVM**, dependency injection via a single
`AppEnvironment`, and **XcodeGen** for a reproducible, merge-friendly Xcode
project (no `.xcodeproj` committed to git).

> Target: iPadOS 17+ · Swift 5.10 · SwiftUI lifecycle · `@Observable` (Observation framework)

## Getting started

The Xcode project is generated from [`project.yml`](project.yml), so it is not
checked into git. Generate it once after cloning:

```bash
brew install xcodegen          # one-time
cd FamilyApp
xcodegen generate              # creates FamilyApp.xcodeproj
open FamilyApp.xcodeproj
```

Then select the **FamilyApp** scheme and run on an iPad simulator.

### Optional tooling

```bash
brew install swiftlint swiftformat
swiftlint                      # lint (config: .swiftlint.yml)
swiftformat .                  # format (config: .swiftformat)
```

## Project structure

```
FamilyApp/
├── project.yml                  # XcodeGen project definition (source of truth)
├── .swiftlint.yml               # Lint rules
├── .swiftformat                 # Formatting rules
├── .gitignore                   # Ignores generated .xcodeproj, build output, etc.
├── Sources/
│   └── FamilyApp/
│       ├── App/                 # Entry point & dependency container
│       │   ├── FamilyAppApp.swift
│       │   └── AppEnvironment.swift
│       ├── Features/            # One folder per screen (View + ViewModel)
│       │   ├── Root/            # NavigationSplitView shell + sidebar
│       │   ├── Dashboard/
│       │   ├── Calendar/
│       │   ├── Tasks/
│       │   └── Settings/
│       ├── Core/                # Cross-feature building blocks
│       │   ├── Models/          # FamilyMember, FamilyTask
│       │   ├── Services/        # FamilyRepository (protocol + in-memory impl)
│       │   ├── Extensions/
│       │   └── DesignSystem/    # Theme tokens
│       └── Resources/           # Info.plist, Assets.xcassets
├── Tests/
│   └── FamilyAppTests/          # Unit tests (XCTest)
└── UITests/
    └── FamilyAppUITests/        # UI tests (XCUITest)
```

## Architecture

- **MVVM** — Each feature has a `View` and, where it has state, an
  `@MainActor @Observable` `ViewModel`. View models receive their dependencies
  as parameters rather than reaching for singletons, which keeps them testable.
- **Dependency injection** — `AppEnvironment` is the composition root. It is
  created in `FamilyAppApp` and injected into the SwiftUI environment. Swap
  `.live()` for `.preview()` in previews/tests.
- **Repository pattern** — `FamilyRepository` is a protocol. The current
  `InMemoryFamilyRepository` (an `actor`) can be replaced with a
  SwiftData/CloudKit-backed implementation without changing any view code.
- **iPad idioms** — `RootView` uses `NavigationSplitView` (sidebar + detail),
  the natural structure for the large iPad canvas. The target is iPad-only
  (`TARGETED_DEVICE_FAMILY = 2`).

## Conventions

- Keep one feature per folder under `Features/`.
- Shared, reusable code goes in `Core/`.
- Prefer protocols for services so implementations stay swappable and testable.
- Run SwiftFormat + SwiftLint before committing.
