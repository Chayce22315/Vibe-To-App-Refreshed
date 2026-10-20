# Vibe To App: Refreshed

a remastered, free-first, iphone-first ai vibe-coding app for creating games and apps from natural-language prompts.

## current milestone

- native swiftui iphone shell
- chat workspace with local demo fallback
- cloud/local provider boundary
- provider settings without hard-coded secrets
- github actions workflow for unsigned simulator builds on a macos runner

## free-first rules

- no mandatory subscription
- never ship provider secrets inside the app
- cloud providers are optional and may have free quotas or limits
- local inference is an adapter, not a promise that every model fits on every iphone
- native ios builds and signing require apple's build tooling; this repo uses github actions macos runners for ci

## build

open `VibeToApp.xcodeproj` in xcode on macos, or run:

```sh
xcodebuild -project VibeToApp.xcodeproj -scheme VibeToApp -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## status

early prototype. the current chat uses a clearly labeled demo response until a real provider adapter is configured. project-file editing, safe diff review, and game/app generation are next milestones.
