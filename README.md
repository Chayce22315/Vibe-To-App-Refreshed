# Vibe To App: Refreshed

a remastered, free-first, iphone-first ai vibe-coding app for creating games and apps from natural-language prompts.

## implemented prototype

- native swiftui iphone shell and chat workspace
- configurable openai-compatible cloud endpoint
- configurable local endpoint, with cloud/local/hybrid routing
- provider credentials stored in ios keychain
- experimental local server adapted from your [blank-code-training-repo](https://github.com/Chayce22315/blank-code-training-repo)
- macos simulator-build workflow through github actions

## free-first rules

- no mandatory subscription
- cloud providers are optional and may have free quotas or limits
- no api keys are hard-coded into the app
- local inference is supported through a server adapter; the baby blank model is experimental and may not produce useful code yet
- no model weights or training datasets are bundled or committed
- native ios builds and signing require apple's tooling; github actions can build simulator targets within available quotas

## local blank model

see [local_blank_server/README.md](local_blank_server/README.md). the server expects a checkpoint trained by the blank model pipeline and exposes an openai-compatible `/v1/chat/completions` endpoint. do not expose it to the public internet.

## build

open `VibeToApp.xcodeproj` in xcode on macos, or run:

```sh
xcodebuild -project VibeToApp.xcodeproj -scheme VibeToApp -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## current limits

the app can send prompts to a configured model, but it does not yet create or modify project files. safe patch review, persistent project workspaces, real code-generation tools, and playable app/game previews are future milestones. the blank model is a research experiment, not a capable coding model.
