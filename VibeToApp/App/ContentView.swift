import SwiftUI

struct ContentView: View {
    @State private var prompt = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "hey! i'm your build buddy. tell me what you want to make, and we'll turn the idea into a real project. ✨")
    ]
    @State private var selectedTab: WorkspaceTab = .build
    @State private var isThinking = false
    @State private var showingProviderSettings = false

    private let agent = AgentCore()

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.04, blue: 0.055).ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if selectedTab == .build {
                    chatWorkspace
                } else if selectedTab == .projects {
                    ProjectsView()
                } else {
                    SettingsView(showingProviderSettings: $showingProviderSettings)
                }

                tabBar
            }
        }
        .sheet(isPresented: $showingProviderSettings) {
            ProviderSettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13).fill(Color.white)
                Image(systemName: "sparkles")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color.black)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("Vibe To App: Refreshed")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("your idea, in motion")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            Button {
                showingProviderSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 13))
            }
            .accessibilityLabel("ai provider settings")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private var chatWorkspace: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if messages.count == 1 {
                            welcomePanel
                        }

                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if isThinking {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white.opacity(0.8))
                                Text("thinking through the build…")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            composer
        }
    }

    private var welcomePanel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("what are we
making today?")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-1.1)
                .foregroundStyle(.white)

            Text("apps, games, experiments, the whole idea factory. start with one sentence.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 9) {
                SuggestionCard(icon: "gamecontroller.fill", title: "a tiny arcade game", detail: "score, controls, and a restart button") {
                    prompt = "make a tiny arcade game with a score, touch controls, and a restart button"
                }
                SuggestionCard(icon: "checklist", title: "a useful little app", detail: "a clean task tracker that saves locally") {
                    prompt = "make a clean task tracker that saves tasks locally"
                }
                SuggestionCard(icon: "wand.and.stars", title: "something weird and wonderful", detail: "help me shape an idea from scratch") {
                    prompt = "help me invent a weird and wonderful app idea, then build the first version"
                }
            }
            .padding(.top, 3)
        }
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var composer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))

                TextField("describe your app or game…", text: $prompt, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(1...5)
                    .foregroundStyle(.white)
                    .submitLabel(.send)
                    .onSubmit(sendPrompt)

                Button(action: sendPrompt) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 38, height: 38)
                        .background(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.35) : Color.white, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isThinking)
                .accessibilityLabel("send prompt")
            }
            .padding(.leading, 15)
            .padding(.trailing, 7)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(Color.white.opacity(0.09), lineWidth: 1))

            HStack(spacing: 6) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("free-first mode")
                Text("·")
                Text("provider setup optional")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.42))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color.black.opacity(0.22))
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(WorkspaceTab.allCases) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(red: 0.045, green: 0.05, blue: 0.065))
        .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1) }
    }

    private func sendPrompt() {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        messages.append(ChatMessage(role: .user, text: text))
        prompt = ""
        isThinking = true

        Task {
            let reply = await agent.respond(to: text)
            await MainActor.run {
                messages.append(ChatMessage(role: .assistant, text: reply))
                isThinking = false
            }
        }
    }
}

private enum WorkspaceTab: String, CaseIterable, Identifiable {
    case build, projects, settings
    var id: String { rawValue }
    var title: String { rawValue }
    var icon: String {
        switch self {
        case .build: return "sparkles"
        case .projects: return "folder"
        case .settings: return "gearshape"
        }
    }
    var selectedIcon: String {
        switch self {
        case .build: return "sparkles"
        case .projects: return "folder.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ChatMessage: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
}

private struct MessageBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 35) }
            Text(message.text)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(14)
                .background(message.role == .user ? Color(red: 0.24, green: 0.28, blue: 0.36) : Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 17))
            if message.role == .assistant { Spacer(minLength: 20) }
        }
    }
}

private struct SuggestionCard: View {
    let icon: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    Text(detail).font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "arrow.up.left").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.35))
            }
            .padding(11)
            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.07), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct ProjectsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("your projects").font(.system(size: 29, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text("your future app factory starts here.").font(.system(size: 14)).foregroundStyle(.white.opacity(0.55))
            VStack(spacing: 12) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.75))
                Text("no projects yet").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                Text("start a build in chat and your projects will show up here.")
                    .font(.system(size: 13)).foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 45)
            .padding(.horizontal, 25)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22))
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SettingsView: View {
    @Binding var showingProviderSettings: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("settings").font(.system(size: 29, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text("keep the tools free, flexible, and under your control.").font(.system(size: 14)).foregroundStyle(.white.opacity(0.55))
            Button { showingProviderSettings = true } label: {
                SettingsRow(icon: "cpu", title: "ai providers", detail: "cloud and on-device options")
            }
            SettingsRow(icon: "lock.shield", title: "privacy", detail: "keys should never be shipped in the app")
            SettingsRow(icon: "arrow.triangle.branch", title: "source control", detail: "github integration is on the roadmap")
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let detail: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(.white).frame(width: 42, height: 42).background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                Text(detail).font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.35))
        }
        .padding(12)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ProviderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cloudProviderBaseURL") private var baseURL = ""
    @AppStorage("cloudProviderModel") private var model = ""
    @AppStorage("localProviderBaseURL") private var localURL = "http://127.0.0.1:8080/v1"
    @AppStorage("aiMode") private var selectedMode = "hybrid"
    @State private var cloudAPIKey = ""
    @State private var localToken = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("routing") {
                    Picker("preferred mode", selection: $selectedMode) {
                        Text("hybrid").tag("hybrid")
                        Text("cloud").tag("cloud")
                        Text("local").tag("local")
                    }
                    Text("cloud services can have free quotas. local inference requires a compatible server or an on-device runtime.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("cloud · openai-compatible") {
                    TextField("base url (optional)", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("model id (optional)", text: $model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("api key (stored in iphone keychain)", text: $cloudAPIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("local endpoint") {
                    TextField("local server url", text: $localURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    SecureField("local server bearer token (optional)", text: $localToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("on iphone, 127.0.0.1 means the iphone itself. for a server on your pc, use its wi-fi ip address and set the same bearer token on the server. never expose the server to the public internet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Text("provider credentials are stored in the iphone keychain. cloud providers may charge or enforce quotas; this app does not include paid ai access.")
                        .font(.footnote)
                }
            }
            .navigationTitle("ai providers")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                cloudAPIKey = KeychainStore.get("cloud-api-key") ?? ""
                localToken = KeychainStore.get("local-provider-token") ?? ""
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done") {
                        if cloudAPIKey.isEmpty { KeychainStore.delete("cloud-api-key") }
                        else { KeychainStore.set(cloudAPIKey, for: "cloud-api-key") }
                        if localToken.isEmpty { KeychainStore.delete("local-provider-token") }
                        else { KeychainStore.set(localToken, for: "local-provider-token") }
                        dismiss()
                    }
                }
            }
        }
    }
}
