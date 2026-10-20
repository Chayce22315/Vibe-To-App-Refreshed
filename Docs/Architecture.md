# architecture

## product direction

vibe-to-app is an iphone-first, native-feeling ai workspace for building games and apps. the first version should be useful on a phone, not a desktop ide squeezed onto a small screen.

## principles

1. **free-first:** no required subscription. cloud services may enforce free quotas; never advertise them as unlimited.
2. **provider-neutral:** use a small `AIProvider` protocol so compatible cloud endpoints and local inference can be added independently.
3. **privacy by default:** no api keys in source, assets, app bundles, or logs. use the ios keychain for user credentials when direct client connections are implemented.
4. **reviewable edits:** future code changes are proposed as patches and reviewed before being applied.
5. **native build pipeline:** github is the source of truth; github actions macos runners can run xcodebuild within the free plan's available minutes.
6. **honest status:** demo mode must say when it has not called a model or changed files.

## planned layers

- **swiftui client:** chat, projects, file browser, diff review, build logs, settings.
- **agent coordinator:** turns a prompt into a plan, then delegates bounded tasks.
- **provider adapters:** openai-compatible cloud endpoint, local openai-compatible server, and eventually on-device inference.
- **workspace engine:** project files, patch application, snapshots, undo.
- **build worker:** github actions workflow using xcodebuild for native ios projects.
- **game/app templates:** begin with swiftui app templates and lightweight spritekit game templates.

## constraints

- an iphone app cannot run xcode itself. native ios builds need a macos build worker.
- `localhost` inside the iphone refers to the iphone, not a different computer.
- local inference performance depends on model size, quantization, memory, and device capabilities.
- github actions and model providers have quotas and terms that can change.
- public cloud endpoints must use https. do not send secrets or private source to an untrusted endpoint.

## milestones

- [x] native swiftui shell and chat demo
- [x] provider-neutral agent boundary
- [x] free-first architecture notes
- [x] macos simulator build workflow
- [ ] secure provider credential storage and real cloud adapter
- [ ] local model adapter
- [ ] project creation and persistent workspace
- [ ] diff preview, apply, undo, and checkpoints
- [ ] github repository connection and build logs
- [ ] game templates and playable previews
