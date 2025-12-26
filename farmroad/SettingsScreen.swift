import Combine
import SwiftUI
import WebKit

struct SettingsScreen: View {
    @ObservedObject var router: AppRouter
    @ObservedObject var viewModel: SettingsViewModel

    @State private var showPrivacy: Bool = false
    @State private var showResetConfirm: Bool = false
    @State private var privacyLoadFailed: Bool = false
    @State private var privacyLastErrorText: String = ""

    var body: some View {
        ZStack {
            AppTheme.screenBackgroundB()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    topBar

                    groupCard(title: "Gameplay", symbol: "gamecontroller.fill") {
                        rowToggle(
                            title: "Haptics",
                            subtitle: "Small taps and feedback",
                            isOn: $viewModel.hapticsEnabled,
                            leadingSymbol: "wave.3.right.circle.fill",
                            a: AppTheme.accentBlue,
                            b: AppTheme.accentPurple
                        )

                        divider

                        rowToggle(
                            title: "Reduced Motion",
                            subtitle: "Less animations",
                            isOn: $viewModel.reducedMotion,
                            leadingSymbol: "figure.walk.motion",
                            a: AppTheme.accentGreen,
                            b: AppTheme.accentBlue
                        )

                        divider

                        rowPicker(
                            title: "Grid Size",
                            subtitle: "Affects new runs",
                            leadingSymbol: "square.grid.3x3.fill",
                            a: AppTheme.accentGreen,
                            b: AppTheme.accentGold
                        )
                    }

                    groupCard(title: "Privacy", symbol: "hand.raised.fill") {
                        rowTextField(
                            title: "App Policy",
                            subtitle: "",
                            text: $viewModel.privacyUrlString,
                            leadingSymbol: "link.circle.fill",
                            a: AppTheme.accentGold,
                            b: AppTheme.accentPurple
                        )

                        divider

                        Button(action: {
                            HapticsEngine.shared.tapLight()
                            if viewModel.validatePrivacyUrl() {
                                privacyLoadFailed = false
                                privacyLastErrorText = ""
                                showPrivacy = true
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "safari.fill")
                                    .font(.system(size: 14, weight: .heavy))
                                Text("Open Privacy Policy")
                                    .font(AppTheme.buttonFont)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .opacity(0.6)
                            }
                            .foregroundStyle(Color.white)
                            .farmButtonSurface(isPrimary: true)
                        }

                        if viewModel.statusText.isEmpty == false {
                            StatusPill(text: viewModel.statusText, isError: viewModel.statusIsError)
                        }

                        if privacyLoadFailed {
                            StatusPill(text: privacyLastErrorText.isEmpty ? "Failed to load policy." : privacyLastErrorText, isError: true)
                        }
                    }

                    groupCard(title: "Data", symbol: "tray.full.fill") {
                        Button(action: {
                            HapticsEngine.shared.tapLight()
                            showResetConfirm = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14, weight: .heavy))
                                Text("Reset Progress")
                                    .font(AppTheme.buttonFont)
                                Spacer()
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .heavy))
                                    .opacity(0.75)
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                            .farmButtonSurface(isPrimary: false)
                        }

                        Text("Consent stays accepted. Grid size affects new runs.")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacySheet(
                url: viewModel.privacyURL(),
                title: "Privacy Policy",
                onClose: {
                    showPrivacy = false
                },
                onFail: { errorText in
                    privacyLoadFailed = true
                    privacyLastErrorText = errorText
                    showPrivacy = false
                }
            )
        }
        .alert("Reset Progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                HapticsEngine.shared.warning()
                viewModel.resetProgressKeepConsent()
            }
        } message: {
            Text("This will reset your farm and economy.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: {
                HapticsEngine.shared.tapLight()
                router.goToMenu()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .heavy))
                    Text("Menu")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.85))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppTheme.strokeSoft, lineWidth: 1)
                )
            }

            Spacer()

            Text("Settings")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.top, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.strokeSoft)
            .frame(height: 1)
            .padding(.horizontal, 6)
    }

    private func groupCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentGradient())
                        .frame(width: 34, height: 34)
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.98))
                }

                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()
            }

            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerXL, style: .continuous)
                .fill(Color.white.opacity(0.90))
                .shadow(radius: 16, y: 10)
        )
    }

    private func rowToggle(title: String, subtitle: String, isOn: Binding<Bool>, leadingSymbol: String, a: Color, b: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [a.opacity(0.95), b.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 34)
                Image(systemName: leadingSymbol)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.98))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private func rowPicker(title: String, subtitle: String, leadingSymbol: String, a: Color, b: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [a.opacity(0.95), b.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 34)
                Image(systemName: leadingSymbol)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.98))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Picker("", selection: $viewModel.preferredGridSizeIndex) {
                ForEach(Array(viewModel.gridSizeOptions().enumerated()), id: \.offset) { idx, name in
                    Text(name).tag(idx)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private func rowTextField(title: String, subtitle: String, text: Binding<String>, leadingSymbol: String, a: Color, b: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [a.opacity(0.95), b.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 34, height: 34)
                    Image(systemName: leadingSymbol)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.98))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
            }

//            TextField("https://…", text: text)
//                .textInputAutocapitalization(.never)
//                .autocorrectionDisabled(true)
//                .keyboardType(.URL)
//                .font(.system(size: 14, weight: .bold, design: .rounded))
//                .padding(.horizontal, 12)
//                .padding(.vertical, 12)
//                .background(
//                    RoundedRectangle(cornerRadius: AppTheme.cornerL, style: .continuous)
//                        .fill(Color.black.opacity(0.05))
//                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: AppTheme.cornerL, style: .continuous)
//                        .stroke(AppTheme.strokeSoft, lineWidth: 1)
//                )
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
}

private struct StatusPill: View {
    let text: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                .font(.system(size: 13, weight: .heavy))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, isError ? AppTheme.accentGold : AppTheme.accentGold)

            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.96))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isError ? [Color(red: 0.90, green: 0.35, blue: 0.35), AppTheme.accentPurple] : [AppTheme.accentGreen, AppTheme.accentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(radius: 14, y: 10)
        .padding(.top, 6)
    }
}

private struct PrivacySheet: View {
    let url: URL?
    let title: String
    let onClose: () -> Void
    let onFail: (String) -> Void

    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = true
    @State private var progress: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    if let url {
                        PrivacyWebView(
                            url: url,
                            canGoBack: $canGoBack,
                            canGoForward: $canGoForward,
                            isLoading: $isLoading,
                            progress: $progress,
                            onFail: onFail
                        )

                        VStack(spacing: 10) {
                            ProgressView(value: min(1.0, max(0.0, progress)))
                                .tint(AppTheme.accentBlue)
                                .opacity(isLoading ? 1 : 0)
                                .animation(.easeInOut(duration: 0.2), value: isLoading)

                            HStack(spacing: 10) {
                                Button(action: {
                                    NotificationCenter.default.post(name: .privacyWebGoBack, object: nil)
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .disabled(canGoBack == false)

                                Button(action: {
                                    NotificationCenter.default.post(name: .privacyWebGoForward, object: nil)
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .disabled(canGoForward == false)

                                Spacer()

                                Button(action: {
                                    NotificationCenter.default.post(name: .privacyWebReload, object: nil)
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .overlay(Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1), alignment: .top)
                    } else {
                        VStack(spacing: 14) {
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 34, weight: .black))
                                .foregroundStyle(AppTheme.accentPurple)

                            Text("Privacy URL is invalid.")
                                .font(AppTheme.titleFont)
                                .foregroundStyle(AppTheme.textPrimary)

                            Button(action: {
                                onFail("Privacy URL is invalid.")
                            }) {
                                Text("Close")
                                    .font(AppTheme.buttonFont)
                                    .foregroundStyle(Color.white)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.cornerL, style: .continuous)
                                            .fill(AppTheme.accentGradient())
                                    )
                            }
                            .padding(.horizontal, 22)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
        }
    }
}

private struct PrivacyWebView: UIViewRepresentable {
    let url: URL
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var progress: Double

    let onFail: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            canGoBack: $canGoBack,
            canGoForward: $canGoForward,
            isLoading: $isLoading,
            progress: $progress,
            onFail: onFail
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.allowsBackForwardNavigationGestures = true
        web.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.goBack), name: .privacyWebGoBack, object: nil)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.goForward), name: .privacyWebGoForward, object: nil)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.reload), name: .privacyWebReload, object: nil)

        web.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20))
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.webView = uiView
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?

        @Binding var canGoBack: Bool
        @Binding var canGoForward: Bool
        @Binding var isLoading: Bool
        @Binding var progress: Double

        let onFail: (String) -> Void

        init(canGoBack: Binding<Bool>, canGoForward: Binding<Bool>, isLoading: Binding<Bool>, progress: Binding<Double>, onFail: @escaping (String) -> Void) {
            _canGoBack = canGoBack
            _canGoForward = canGoForward
            _isLoading = isLoading
            _progress = progress
            self.onFail = onFail
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "estimatedProgress", let web = object as? WKWebView {
                DispatchQueue.main.async {
                    self.progress = web.estimatedProgress
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading = true
                self.canGoBack = webView.canGoBack
                self.canGoForward = webView.canGoForward
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading = false
                self.canGoBack = webView.canGoBack
                self.canGoForward = webView.canGoForward
                self.progress = 1.0
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.isLoading = false
                self.canGoBack = webView.canGoBack
                self.canGoForward = webView.canGoForward
                self.onFail(error.localizedDescription)
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.isLoading = false
                self.onFail(error.localizedDescription)
            }
        }

        @objc func goBack() {
            webView?.goBack()
        }

        @objc func goForward() {
            webView?.goForward()
        }

        @objc func reload() {
            webView?.reload()
        }
    }
}

private extension Notification.Name {
    static let privacyWebGoBack = Notification.Name("privacy.web.goback")
    static let privacyWebGoForward = Notification.Name("privacy.web.goforward")
    static let privacyWebReload = Notification.Name("privacy.web.reload")
}
