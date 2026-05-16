// DjGuardApp.swift
// macOS Menu-Bar App – v2
// Neu: Peer-Verbindung, Client-Liste, Venue-Auswahl, History-Fenster

import AppKit
import SwiftUI
import Network
import Combine
import Darwin

// MARK: - Localization
enum AppLanguage: String, CaseIterable {
    case system  = "system"
    case english = "en"
    case german  = "de"

    var displayName: String {
        switch self {
        case .system:  return "System"
        case .english: return "English"
        case .german:  return "Deutsch"
        }
    }
}

final class L: ObservableObject {
    static let shared = L()
    @Published var lang: AppLanguage = .system

    private static let langKey        = "DjGuardLanguage"
    private static let firstLaunchKey = "DjGuardLanguageSelected"

    var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: Self.firstLaunchKey)
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.langKey) ?? "system"
        lang = AppLanguage(rawValue: raw) ?? .system
    }

    func set(_ l: AppLanguage) {
        lang = l
        UserDefaults.standard.set(l.rawValue, forKey: Self.langKey)
        UserDefaults.standard.set(true, forKey: Self.firstLaunchKey)
        DispatchQueue.main.async {
            // App neu starten damit alle Texte in der neuen Sprache erscheinen
            let url = Bundle.main.bundleURL
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = ["-n", url.path]
            try? task.run()
            NSApp.terminate(nil)
        }
    }

    func t(_ key: String) -> String {
        let isDE: Bool
        switch lang {
        case .german:  isDE = true
        case .english: isDE = false
        case .system:  isDE = Locale.current.language.languageCode?.identifier == "de"
        }
        return isDE ? (L.de[key] ?? L.en[key] ?? key) : (L.en[key] ?? key)
    }

    static let en: [String: String] = [
        "menu.djGuardBy":        "DjGuard by Dj Kay-Cut",
        "menu.noConnections":    "⚫ No DJ connections",
        "menu.djsConnected":     "🟢 %d DJ(s) connected",
        "menu.history":          "Show History",
        "menu.resetSession":     "Reset Session",
        "menu.connectDJ":        "Connect DJ…",
        "menu.showClients":      "Show Clients",
        "menu.settings":         "Settings…",
        "menu.quit":             "Quit",
        "tab.appearance":        "Appearance",
        "tab.matching":          "Matching",
        "tab.venue":             "Venue",
        "tab.network":           "Network",
        "appearance.alertBubble":"Alert Circle",
        "appearance.bgColor":    "Background Color",
        "appearance.textColor":  "Text Color",
        "appearance.size":       "Size",
        "appearance.fontSize":   "Font Size",
        "appearance.duration":   "Duration",
        "appearance.opacity":    "Opacity",
        "appearance.preview":    "Preview",
        "appearance.previewSub": "Click to test on screen",
        "appearance.testAlert":  "Test Alert",
        "appearance.testSent":   "✓ Sent",
        "appearance.resetPos":   "Reset Circle Position",
        "appearance.resetPosSub":"Moves circle to screen center",
        "appearance.center":     "Center",
        "appearance.language":   "Language",
        "history.title":         "DjGuard – History",
        "history.search":        "Search…",
        "history.empty":         "No tracks played yet",
        "history.noResults":     "No results",
        "history.duplicate":     "DUPLICATE",
        "history.clearSession":  "Clear Session",
        "history.tracks":        "track(s)",
        "circle.alreadyPlayed":  "⛔  ALREADY PLAYED",
        "matching.threshold":    "Similarity Threshold",
        "matching.minPlay":      "Min. Play Duration",
        "matching.minPlaySub":   "Track must play this long to count as played",
        "matching.windowMode":   "Time Window",
        "matching.session":      "Session",
        "matching.hours":        "Hours",
        "venue.name":            "Venue Name",
        "venue.id":              "Venue ID",
        "venue.newID":           "New ID",
        "network.deviceName":    "Device Name",
        "network.port":          "Port",
        "network.myIP":          "My IP",
        "network.thisDevice":    "This Device",
        "matching.timeWindow":   "Matching Time Window",
        "matching.recommended":  "70–85% recommended. Higher = more precise, fewer hits.",
        "matching.since":        "Since App Start (this session)",
        "matching.lastHours":    "Last X Hours",
        "venue.isolation":       "Each venue has isolated history. New club → new venue ID.",
        "network.ipAddress":     "IP Address",
        "network.yourAddress":   "Your address for others:",
        "network.wlanInfo":      "All DJs must be on the same WiFi.",
        "network.noWlan":        "No WiFi? Main DJ opens a hotspot:\nSystem Settings → General → Sharing → Internet Sharing",
        "matching.mode":         "Mode",
        "venue.newIDBtn":        "New ID",
        "venue.nameLabel":       "Name",
        "connect.otherDJs":      "Connect other DJs",

        "venue.location":        "Venue (Location)",
        "firstLaunch.title":     "Welcome to DjGuard",
        "firstLaunch.message":   "Please select your preferred language:",
        "firstLaunch.continue":  "Continue",
        "install.wait":          "This takes about 30 seconds.",
        "connect.hint":          "(Find it in their DjGuard → Settings → Network)",
        "clients.title":         "Connected Devices",
        "status.connected":      "🟢 %d DJ(s) connected",
        "install.homebrew":      "Homebrew required",
        "install.python":        "Python 3.11 required",
        "settings.title":        "DjGuard – Settings",
        "network.visibleName":   "Name (visible to other DJs)",
        "install.needsPython":   "DjGuard requires Python 3.11 or newer.",
    ]

    static let de: [String: String] = [
        "menu.djGuardBy":        "DjGuard by Dj Kay-Cut",
        "menu.noConnections":    "⚫ Keine DJ-Verbindungen",
        "menu.djsConnected":     "🟢 %d DJ(s) verbunden",
        "menu.history":          "History anzeigen",
        "menu.resetSession":     "Session zurücksetzen",
        "menu.connectDJ":        "Mit DJ verbinden…",
        "menu.showClients":      "Clients anzeigen",
        "menu.settings":         "Einstellungen…",
        "menu.quit":             "Beenden",
        "tab.appearance":        "Aussehen",
        "tab.matching":          "Matching",
        "tab.venue":             "Venue",
        "tab.network":           "Netzwerk",
        "appearance.alertBubble":"Alert-Blase",
        "appearance.bgColor":    "Hintergrundfarbe",
        "appearance.textColor":  "Textfarbe",
        "appearance.size":       "Grösse",
        "appearance.fontSize":   "Schriftgrösse",
        "appearance.duration":   "Anzeigedauer",
        "appearance.opacity":    "Transparenz",
        "appearance.preview":    "Vorschau",
        "appearance.previewSub": "Klick zum Testen auf dem Bildschirm",
        "appearance.testAlert":  "Test-Alert",
        "appearance.testSent":   "✓ Gesendet",
        "appearance.resetPos":   "Kreis-Position zurücksetzen",
        "appearance.resetPosSub":"Setzt den Kreis in die Bildschirmmitte",
        "appearance.center":     "Zentrieren",
        "appearance.language":   "Sprache",
        "history.title":         "DjGuard – History",
        "history.search":        "Suchen…",
        "history.empty":         "Noch keine Tracks gespielt",
        "history.noResults":     "Keine Treffer",
        "history.duplicate":     "DUPLIKAT",
        "history.clearSession":  "Session löschen",
        "history.tracks":        "Track(s)",
        "circle.alreadyPlayed":  "⛔  BEREITS GESPIELT",
        "matching.threshold":    "Ähnlichkeitsschwelle",
        "matching.minPlay":      "Mindest-Spieldauer",
        "matching.minPlaySub":   "Track muss mindestens so lange gespielt werden",
        "matching.windowMode":   "Zeitfenster",
        "matching.session":      "Session",
        "matching.hours":        "Stunden",
        "venue.name":            "Venue-Name",
        "venue.id":              "Venue-ID",
        "venue.newID":           "Neue ID",
        "network.deviceName":    "Gerätename",
        "network.port":          "Port",
        "network.myIP":          "Meine IP",
        "network.thisDevice":    "Dieses Gerät",
        "matching.timeWindow":   "Matching-Zeitfenster",
        "matching.recommended":  "70–85% empfohlen. Höher = präziser, weniger Treffer.",
        "matching.since":        "Seit App-Start (diese Session)",
        "matching.lastHours":    "Letzte X Stunden",
        "venue.isolation":       "Jede Venue hat eine isolierte History. Neuer Club → neue Venue-ID.",
        "network.ipAddress":     "IP-Adresse",
        "network.yourAddress":   "Deine Adresse für andere:",
        "network.wlanInfo":      "Alle DJs müssen im gleichen WLAN sein.",
        "network.noWlan":        "Kein WLAN? Haupt-DJ öffnet einen Hotspot:\nSystemeinstellungen → Allgemein → Teilen → Internetfreigabe",
        "matching.mode":         "Modus",
        "venue.newIDBtn":        "Neue ID",
        "venue.nameLabel":       "Name",
        "connect.otherDJs":      "Andere DJs verbinden",

        "venue.location":        "Venue (Location)",
        "firstLaunch.title":     "Willkommen bei DjGuard",
        "firstLaunch.message":   "Bitte wähle deine bevorzugte Sprache:",
        "firstLaunch.continue":  "Weiter",
        "install.wait":          "Dies dauert ca. 30 Sekunden.",
        "connect.hint":          "(Zu finden in dessen DjGuard → Einstellungen → Netzwerk)",
        "clients.title":         "Verbundene Geräte",
        "status.connected":      "🟢 %d DJ(s) verbunden",
        "install.homebrew":      "Homebrew wird benötigt",
        "install.python":        "Python 3.11 wird benötigt",
        "settings.title":        "DjGuard – Einstellungen",
        "network.visibleName":   "Name (sichtbar für andere DJs)",
        "install.needsPython":   "DjGuard benötigt Python 3.11 oder neuer.",
    ]
}

// Shorthand global function
func t(_ key: String) -> String { L.shared.t(key) }


@main
struct DjGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let settings = SettingsModel()
    let runtimeState = RuntimeState()
    var overlay: OverlayPanel?
    var backend: BackendController!
    var wsClient: WebSocketClient!
    var installer: DependencyInstaller!
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        settings.load()
        setupStatusBar()

        // First launch: ask for language
        if L.shared.isFirstLaunch {
            showLanguageSelectionDialog()
        }

        installer = DependencyInstaller()
        installer.checkAndInstall { [weak self] ready in
            DispatchQueue.main.async {
                if ready {
                    self?.launchApp()
                } else {
                    self?.showDependencyError()
                }
            }
        }
    }

    func applicationWillTerminate(_ n: Notification) {
        backend?.stop()
        wsClient?.disconnect()
    }

    func showLanguageSelectionDialog() {
        let alert = NSAlert()
        alert.messageText     = "Welcome to DjGuard / Willkommen bei DjGuard"
        alert.informativeText = "Please select your language / Bitte wähle deine Sprache:"
        alert.addButton(withTitle: "English")
        alert.addButton(withTitle: "Deutsch")
        alert.addButton(withTitle: "System")
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:  L.shared.set(.english)
        case .alertSecondButtonReturn: L.shared.set(.german)
        default:                       L.shared.set(.system)
        }
    }

    func launchApp() {
        overlay = OverlayPanel(settings: settings)
        backend = BackendController(settings: settings)
        wsClient = WebSocketClient(settings: settings)

        wsClient.onEvent = { [weak self] e in
            DispatchQueue.main.async { self?.handleEvent(e) }
        }
        wsClient.onClientList = { [weak self] list in
            DispatchQueue.main.async {
                self?.runtimeState.connectedClients = list
                self?.rebuildMenu()
            }
        }
        wsClient.onServerInfo = { [weak self] info in
            DispatchQueue.main.async {
                self?.runtimeState.serverInfo = info
            }
        }
        wsClient.onConnected = { [weak self] in
            DispatchQueue.main.async { self?.overlay?.show() }
        }

        settings.objectWillChange
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.settings.save()
                self?.overlay?.reloadContent()
                self?.wsClient?.sendSettings()
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DjGuardTestAlert"),
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let fakeDict: [String: Any] = [
                "type": "track_event",
                "track": [
                    "artist": "Michael Jackson",
                    "title": "Beat It",
                    "album": "Thriller",
                    "display": "Michael Jackson – Beat It",
                    "played_at": Date().timeIntervalSince1970
                ],
                "is_duplicate": true,
                "is_exact": true,
                "score": 100,
                "matched": ["display": "Michael Jackson – Beat It"],
                "similar": [],
                "history_count": 1,
                "timestamp": Date().timeIntervalSince1970,
                "venue_id": ""
            ]
            self.overlay?.showAlert(TrackEvent(dict: fakeDict))
        }

        // Kreis-Position zurücksetzen
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DjGuardResetCirclePosition"),
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let screen = NSScreen.main ?? NSScreen.screens[0]
            let sf     = screen.frame
            let size   = self.settings.alertSize
            let cx     = sf.midX
            let cy     = sf.midY
            UserDefaults.standard.set([Double(cx), Double(cy)],
                                      forKey: "overlayCirclePosition")
            if let panel = self.overlay?.panel {
                panel.setFrameOrigin(NSPoint(x: cx - size / 2, y: cy - size / 2))
            }
        }

        backend.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.wsClient.connect(to: "127.0.0.1", port: self.settings.wsPort)
        }
        overlay?.show()
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "music.note.list",
            accessibilityDescription: "DjGuard"
        )
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        let header = NSMenuItem(title: t("menu.djGuardBy"), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        let count = runtimeState.connectedClients.count
        let status = count == 0
            ? t("menu.noConnections")
            : String(format: t("status.connected"), count)
        let statusItem2 = NSMenuItem(title: status, action: nil, keyEquivalent: "")
        statusItem2.isEnabled = false
        menu.addItem(statusItem2)

        let venue = NSMenuItem(title: "📍 \(settings.venueName)", action: nil, keyEquivalent: "")
        venue.isEnabled = false
        menu.addItem(venue)

        menu.addItem(.separator())
        menu.addItem(item(t("menu.history"), #selector(showHistory), "j"))
        menu.addItem(item(t("menu.resetSession"), #selector(resetSession), "r"))
        menu.addItem(item(t("menu.connectDJ"), #selector(showConnect), "k"))
        menu.addItem(item(t("menu.showClients"), #selector(showClients), "l"))
        menu.addItem(.separator())
        menu.addItem(item(t("menu.settings"), #selector(openSettings), ","))
        menu.addItem(.separator())
        // Beenden: target muss nil sein damit NSApp den terminate: Selector empfängt
        let quitItem = NSMenuItem(
            title: t("menu.quit"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = nil   // nil = Responder Chain → NSApp empfängt terminate:
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    func item(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        return i
    }

    @objc func openSettings() {
        SettingsWindowController.show(settings: settings)
    }

    @objc func showHistory() {
        HistoryWindowController.show()
    }

    @objc func resetSession() {
        wsClient?.send(["action": "reset_history"])
        overlay?.clearHistory()
    }

    @objc func showConnect() {
        ConnectWindow.show(settings: settings) { [weak self] ip, port in
            self?.wsClient.connectToPeer(ip: ip, port: port)
        }
    }

    @objc func showClients() {
        ClientListWindow.show(clients: runtimeState.connectedClients)
    }

    func handleEvent(_ event: TrackEvent) {
        rebuildMenu()
        if event.isDuplicate {
            overlay?.showAlert(event)
            flashStatusIcon()
        } else {
            overlay?.addToHistory(event)
        }
    }

    func flashStatusIcon() {
        statusItem.button?.image = NSImage(
            systemSymbolName: "exclamationmark.circle.fill",
            accessibilityDescription: "DUPLICATE"
        )?.tinted(.systemRed)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.statusItem.button?.image = NSImage(
                systemSymbolName: "music.note.list",
                accessibilityDescription: "DjGuard"
            )
        }
    }

    func showDependencyError() {
        let a = NSAlert()
        a.messageText = "Setup fehlgeschlagen"
        a.informativeText = """
        Python3 und/oder die nötigen Pakete konnten nicht installiert werden.

        Bitte Terminal öffnen und ausführen:
        brew install python3
        pip3 install websockets rapidfuzz
        """
        a.alertStyle = .critical
        a.addButton(withTitle: "OK")
        a.runModal()
    }
}

final class DependencyInstaller {
    func checkAndInstall(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.step1_ensureHomebrew(completion: completion)
        }
    }

    private func step1_ensureHomebrew(completion: @escaping (Bool) -> Void) {
        let brewPath = self.findBrew()
        if brewPath != nil {
            self.step2_ensurePython(brew: brewPath!, completion: completion)
            return
        }

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = t("install.homebrew")
            alert.informativeText = """
            DjGuard installiert fehlende Abhängigkeiten automatisch über Homebrew.

            Homebrew ist ein kostenloses Paketverwaltungssystem für macOS und wird jetzt installiert.

            Dies dauert 3–5 Minuten.
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Homebrew installieren")
            alert.addButton(withTitle: "Abbrechen")

            guard alert.runModal() == .alertFirstButtonReturn else {
                completion(false)
                return
            }

            ProgressWindow.show(message: "Installiere Homebrew…") { done in
                let ok = self.runScript("/bin/bash", args: [
                    "-c",
                    """
                    NONINTERACTIVE=1 /bin/bash -c \
                    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    """
                ])
                DispatchQueue.main.async {
                    done()
                    if ok {
                        DispatchQueue.global().async {
                            self.step2_ensurePython(
                                brew: self.findBrew() ?? "/opt/homebrew/bin/brew",
                                completion: completion
                            )
                        }
                    } else {
                        self.showFatalError(
                            title: "Homebrew-Installation fehlgeschlagen",
                            detail: """
                            Bitte Homebrew manuell installieren:
                            https://brew.sh

                            Dann DjGuard neu starten.
                            """,
                            completion: completion
                        )
                    }
                }
            }
        }
    }

    private func step2_ensurePython(brew: String, completion: @escaping (Bool) -> Void) {
        if let python = findPython() {
            step3_ensurePackages(python: python, completion: completion)
            return
        }

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = t("install.python")
            alert.informativeText = """
            \(t("install.needsPython"))

            Das System-Python (3.9) ist zu alt.
            Python 3.11 wird jetzt über Homebrew installiert.

            Dies dauert 2–4 Minuten.
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Python installieren")
            alert.addButton(withTitle: "Abbrechen")

            guard alert.runModal() == .alertFirstButtonReturn else {
                completion(false)
                return
            }

            ProgressWindow.show(message: "Installiere Python 3.11…") { done in
                let brewDir = (brew as NSString).deletingLastPathComponent
                let ok = self.runScript("/bin/bash", args: [
                    "-c",
                    "PATH=\"\(brewDir):/usr/local/bin:/usr/bin\" brew install python@3.11"
                ])
                DispatchQueue.main.async {
                    done()
                    if ok, let python = self.findPython() {
                        DispatchQueue.global().async {
                            self.step3_ensurePackages(python: python, completion: completion)
                        }
                    } else {
                        self.showFatalError(
                            title: "Python-Installation fehlgeschlagen",
                            detail: """
                            Bitte Python manuell installieren:
                            brew install python@3.11

                            Dann DjGuard neu starten.
                            """,
                            completion: completion
                        )
                    }
                }
            }
        }
    }

    private func step3_ensurePackages(python: String, completion: @escaping (Bool) -> Void) {
        let missing = missingPackages(python: python)
        if missing.isEmpty {
            completion(true)
            return
        }

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Python-Pakete werden installiert"
            alert.informativeText = """
            DjGuard installiert jetzt:
            • \(missing.joined(separator: "\n• "))

            Dies dauert ca. 30 Sekunden.
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Installieren")
            alert.addButton(withTitle: "Abbrechen")

            guard alert.runModal() == .alertFirstButtonReturn else {
                completion(false)
                return
            }

            ProgressWindow.show(message: "Installiere \(missing.joined(separator: ", "))…") { done in
                let ok = self.runScript(python, args: [
                    "-m", "pip", "install", "--quiet", "--break-system-packages"
                ] + missing) || self.runScript(python, args: [
                    "-m", "pip", "install", "--quiet"
                ] + missing)

                DispatchQueue.main.async {
                    done()
                    if ok {
                        completion(true)
                    } else {
                        self.showFatalError(
                            title: "Paket-Installation fehlgeschlagen",
                            detail: """
                            Bitte Terminal öffnen:
                            pip3 install \(missing.joined(separator: " "))

                            Dann DjGuard neu starten.
                            """,
                            completion: completion
                        )
                    }
                }
            }
        }
    }

    func findBrew() -> String? {
        let paths = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew"
        ]
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func findPython() -> String? {
        let paths = [
            Bundle.main.path(forResource: "python3", ofType: nil) ?? "",
            "/opt/homebrew/opt/python@3.13/bin/python3.13",
            "/opt/homebrew/opt/python@3.12/bin/python3.12",
            "/opt/homebrew/opt/python@3.11/bin/python3.11",
            "/opt/homebrew/bin/python3",
            "/usr/local/opt/python@3.13/bin/python3.13",
            "/usr/local/opt/python@3.12/bin/python3.12",
            "/usr/local/opt/python@3.11/bin/python3.11",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]

        for path in paths where !path.isEmpty {
            guard FileManager.default.isExecutableFile(atPath: path) else { continue }
            let p = Process()
            p.executableURL = URL(fileURLWithPath: path)
            p.arguments = ["-c", "import sys; exit(0 if sys.version_info >= (3,11) else 1)"]
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
            try? p.run()
            p.waitUntilExit()
            if p.terminationStatus == 0 { return path }
        }
        return nil
    }

    private func missingPackages(python: String) -> [String] {
        ["websockets", "rapidfuzz"].filter { pkg in
            let p = Process()
            p.executableURL = URL(fileURLWithPath: python)
            p.arguments = ["-c", "import \(pkg)"]
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
            try? p.run()
            p.waitUntilExit()
            return p.terminationStatus != 0
        }
    }

    @discardableResult
    private func runScript(_ path: String, args: [String]) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
        return p.terminationStatus == 0
    }

    @discardableResult
    func shell(_ path: String, args: [String]) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
        return p.terminationStatus
    }

    @discardableResult
    func shellOutput(_ path: String, args: [String]) -> Int32 {
        return shell(path, args: args)
    }

    private func showFatalError(title: String, detail: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let a = NSAlert()
            a.messageText = title
            a.informativeText = detail
            a.alertStyle = .critical
            a.addButton(withTitle: "OK")
            a.runModal()
            completion(false)
        }
    }
}

final class RuntimeState: ObservableObject {
    @Published var connectedClients: [[String: Any]] = []
    @Published var serverInfo: [String: Any] = [:]
}

final class SettingsModel: ObservableObject {
    @Published var alertColor: Color = Color.red.opacity(0.92)
    @Published var alertTextColor: Color = .white
    @Published var alertSize: Double = 260
    @Published var alertDuration: Double = 6
    @Published var fontSize: Double = 28
    @Published var historyBgColor: Color = Color.black.opacity(0.88)
    @Published var showHistory: Bool = true
    @Published var backgroundOpacity: Double = 1.0
    @Published var overlayScreen: Int = 0

    @Published var matchThreshold:  Int    = 82
    @Published var windowMode:      String = "session"
    @Published var windowHours:     Double = 6.0
    @Published var minPlaySeconds:  Int    = 15  // Mindest-Spieldauer

    @Published var venueId: String = defaultVenueId()
    @Published var venueName: String = "Standard"

    @Published var wsPort: Int = 8765
    @Published var nodeName: String = Host.current().localizedName ?? "DJ-Mac"

    static func defaultVenueId() -> String {
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        let host = Host.current().localizedName?.components(separatedBy: ".").first ?? "mac"
        return "\(date)_\(host)"
    }

    private var savePath: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DjGuard")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("settings.json")
    }

    func load() {
        guard let data = try? Data(contentsOf: savePath),
              let d = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        alertSize = d["alertSize"] as? Double ?? alertSize
        alertDuration = d["alertDuration"] as? Double ?? alertDuration
        fontSize = d["fontSize"] as? Double ?? fontSize
        showHistory = d["showHistory"] as? Bool ?? showHistory
        backgroundOpacity = d["opacity"] as? Double ?? backgroundOpacity
        matchThreshold = d["matchThreshold"] as? Int    ?? matchThreshold
        windowMode     = d["windowMode"]     as? String ?? windowMode
        windowHours    = d["windowHours"]    as? Double ?? windowHours
        minPlaySeconds = d["minPlaySeconds"] as? Int    ?? minPlaySeconds
        venueId = d["venueId"] as? String ?? venueId
        venueName = d["venueName"] as? String ?? venueName
        wsPort = d["wsPort"] as? Int ?? wsPort
        nodeName = d["nodeName"] as? String ?? nodeName
        overlayScreen = d["overlayScreen"] as? Int ?? overlayScreen
    }

    func save() {
        let d: [String: Any] = [
            "alertSize": alertSize,
            "alertDuration": alertDuration,
            "fontSize": fontSize,
            "showHistory": showHistory,
            "opacity": backgroundOpacity,
            "matchThreshold":  matchThreshold,
            "windowMode":       windowMode,
            "minPlaySeconds":   minPlaySeconds,
            "windowHours": windowHours,
            "venueId": venueId,
            "venueName": venueName,
            "wsPort": wsPort,
            "nodeName": nodeName,
            "overlayScreen": overlayScreen
        ]
        if let data = try? JSONSerialization.data(withJSONObject: d, options: .prettyPrinted) {
            try? data.write(to: savePath, options: .atomic)
        }
    }
}

final class WebSocketClient {
    var onEvent: ((TrackEvent) -> Void)?
    var onClientList: (([[String: Any]]) -> Void)?
    var onServerInfo: (([String: Any]) -> Void)?
    var onConnected: (() -> Void)?

    private var task: URLSessionWebSocketTask?
    private var reconnect: DispatchWorkItem?
    private var isRunning = false
    private let settings: SettingsModel

    init(settings: SettingsModel) {
        self.settings = settings
    }

    func connect(to host: String = "127.0.0.1", port: Int? = nil) {
        let p = port ?? settings.wsPort
        guard let url = URL(string: "ws://\(host):\(p)") else { return }
        isRunning = true
        let session = URLSession(configuration: .default)
        task = session.webSocketTask(with: url)
        task?.resume()
        sendHello()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.onConnected?()
        }
        receive()
    }

    func connectToPeer(ip: String, port: Int) {
        guard let url = URL(string: "ws://\(ip):\(port)") else { return }
        let session = URLSession(configuration: .default)
        let peerTask = session.webSocketTask(with: url)
        peerTask.resume()

        let hello: [String: Any] = [
            "action": "hello",
            "name": settings.nodeName,
            "device": "Mac",
            "is_peer": true,
            "node_id": UUID().uuidString,
            "venue_id": settings.venueId
        ]

        if let data = try? JSONSerialization.data(withJSONObject: hello),
           let str = String(data: data, encoding: .utf8) {
            peerTask.send(.string(str)) { _ in }
        }
    }

    func disconnect() {
        isRunning = false
        reconnect?.cancel()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    func send(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(str)) { _ in }
    }

    func sendHello() {
        send([
            "action": "hello",
            "name": settings.nodeName,
            "device": "Mac",
            "is_peer": false,
            "venue_id": settings.venueId
        ])
    }

    func sendSettings() {
        send([
            "action": "update_settings",
            "data": [
                "matchThreshold": settings.matchThreshold,
                "minPlaySeconds": settings.minPlaySeconds,
                "venueId": settings.venueId,
                "windowMode": settings.windowMode,
                "windowHours": settings.windowHours
            ]
        ])
    }

    private func receive() {
        task?.receive { [weak self] result in
            guard let self, self.isRunning else { return }
            switch result {
            case .success(let msg):
                if case .string(let text) = msg { self.handle(text) }
                self.receive()
            case .failure:
                self.scheduleReconnect()
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = dict["type"] as? String else { return }

        switch type {
        case "track_event":
            let event = TrackEvent(dict: dict)
            onEvent?(event)
        case "client_list":
            let clients = dict["clients"] as? [[String: Any]] ?? []
            onClientList?(clients)
        case "server_info":
            onServerInfo?(dict)
        case "welcome":
            let clients = dict["clients"] as? [[String: Any]] ?? []
            onClientList?(clients)
            if let histArr = dict["history"] as? [[String: Any]] {
                DispatchQueue.main.async {
                    for h in histArr.reversed() {
                        let artist = h["artist"] as? String ?? ""
                        let title = h["title"] as? String ?? ""
                        let display = h["display"] as? String ?? (artist.isEmpty ? title : "\(artist) – \(title)")
                        HistoryStore.shared.items.append(
                            HistoryStore.HistoryItem(
                                artist: artist,
                                title: title,
                                display: display,
                                isDup: false,
                                time: Date()
                            )
                        )
                    }
                }
            }
        default:
            break
        }
    }

    private func scheduleReconnect() {
        guard isRunning else { return }
        reconnect?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.connect(to: "127.0.0.1", port: self.settings.wsPort)
        }
        reconnect = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }
}

struct TrackEvent {
    let artist: String
    let title: String
    let displayName: String
    let isDuplicate: Bool
    let isExact: Bool
    let score: Int
    let matchedDisplay: String?
    let similar: [[String: Any]]

    init(dict: [String: Any]) {
        // Backend sendet bei is_loaded=true bereits matched als "track"
        // sodass artist/title den schon gespielten Track zeigen
        let track       = dict["track"]        as? [String: Any] ?? [:]
        let loadedTrack = dict["loaded_track"] as? [String: Any]  // geladener Track (Kontext)
        artist      = track["artist"]  as? String ?? ""
        title       = track["title"]   as? String ?? ""
        displayName = track["display"] as? String ?? "\(artist) – \(title)"
        isDuplicate = dict["is_duplicate"] as? Bool ?? false
        isExact     = dict["is_exact"]     as? Bool ?? false
        score       = dict["score"]        as? Int  ?? 0
        let m       = dict["matched"]      as? [String: Any]
        matchedDisplay = m?["display"] as? String
        similar     = dict["similar"]  as? [[String: Any]] ?? []
        _ = loadedTrack  // für zukünftige Nutzung
    }

    var alertJS: String {
        let simArr = similar.prefix(5).compactMap { s -> String? in
            guard let disp = s["display"] as? String, let sc = s["score"] as? Int else { return nil }
            let esc = disp.replacingOccurrences(of: "\"", with: "\\\"")
            return "{\"display\":\"\(esc)\",\"score\":\(sc)}"
        }.joined(separator: ",")
        let matchStr = matchedDisplay.map { "\"\($0.replacingOccurrences(of: "\"", with: "\\\""))\"" } ?? "null"
        let a = artist.replacingOccurrences(of: "\"", with: "\\\"")
        let t = title.replacingOccurrences(of: "\"", with: "\\\"")
        return "{\"artist\":\"\(a)\",\"title\":\"\(t)\",\"display\":\"\(displayName.replacingOccurrences(of: "\"", with: "\\\""))\"},\(matchStr),\(score),[\(simArr)],\(isExact)"
    }
}

final class OverlayPanel: NSObject {
    private let settings: SettingsModel
    var panel: NSPanel?        // internal access für Position-Reset
    private var view: PersistentCircleView?
    private var alertTimer: Timer?

    private static let posKey = "overlayCirclePosition"

    init(settings: SettingsModel) {
        self.settings = settings
        super.init()
    }

    func show() {
        if panel == nil { buildPanel() }
        panel?.orderFrontRegardless()
        // Startup-Animation: DjGuard Branding für 6 Sekunden
        showStartupBranding()
    }

    private func showStartupBranding() {
        view?.activateWithColor(
            label:    "DjGuard",
            subtitle: "by Dj Kay-Cut",
            color:    NSColor(red: 0.25, green: 0.15, blue: 0.70, alpha: 0.95)
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            self?.view?.deactivate()
        }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func reloadContent() {
        view?.settings = settings
        view?.needsDisplay = true
        resizeIfNeeded()
    }

    // Entfernt Serato-Suffixe für Anzeige im Kreis
    // "My Way Remix [Xtendz] - HD - Dirty" → "My Way Remix"
    static func cleanTitle(_ title: String) -> String {
        var c = title
        for _ in 0..<6 {
            let prev = c
            // Brackets: [Xtendz], [Single], [Intro - Clean] etc.
            c = c.replacingOccurrences(of: #"\s*\[[^\]]*\]"#, with: "",
                options: .regularExpression)
            // Parens: (Dirty), (Clean), (Single) etc.
            c = c.replacingOccurrences(of: #"\s*\([^\)]*\)"#, with: "",
                options: .regularExpression)
            // Trailing: - HD, - Dirty, - Clean etc.
            c = c.replacingOccurrences(
                of: #"\s*-\s*(HD|Dirty|Clean|Explicit|Extended|Original|Instrumental|Acapella|Radio Edit)\s*$"#,
                with: "", options: [.regularExpression, .caseInsensitive])
            c = c.trimmingCharacters(in: .init(charactersIn: " -"))
            if c == prev { break }
        }
        return c.isEmpty ? title : c
    }

    private func resizeIfNeeded() {
        guard let p = panel, let v = view else { return }
        let size = settings.alertSize
        let old = p.frame
        let cx = old.midX
        let cy = old.midY
        let newFrame = NSRect(x: cx - size / 2, y: cy - size / 2, width: size, height: size)
        p.setFrame(newFrame, display: true)
        v.frame = NSRect(origin: .zero, size: NSSize(width: size, height: size))
    }

    private func buildPanel() {
        let size = settings.alertSize
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let sf = screen.frame

        var cx: CGFloat = sf.midX
        var cy: CGFloat = sf.midY
        if let saved = UserDefaults.standard.array(forKey: Self.posKey) as? [Double] {
            cx = CGFloat(saved[0])
            cy = CGFloat(saved[1])
        }

        let p = CirclePanel(
            contentRect: NSRect(x: cx - size / 2, y: cy - size / 2, width: size, height: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        p.isMovableByWindowBackground = false
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false

        let v = PersistentCircleView(
            frame: NSRect(origin: .zero, size: NSSize(width: size, height: size)),
            settings: settings
        )
        v.onDragEnd = { [weak p] in
            guard let p else { return }
            let mid = NSPoint(x: p.frame.midX, y: p.frame.midY)
            UserDefaults.standard.set([Double(mid.x), Double(mid.y)], forKey: Self.posKey)
        }

        p.contentView = v
        self.panel = p
        self.view = v
        p.orderFrontRegardless()
    }

    func showAlert(_ event: TrackEvent) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.showAlert(event) }
            return
        }
        if self.panel == nil { self.buildPanel() }
        self.panel?.orderFrontRegardless()
        self.alertTimer?.invalidate()

        let cleanArtist = event.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        // Titel bereinigen: [Xtendz], - HD - Dirty etc. entfernen
        let rawTitle = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTitle = OverlayPanel.cleanTitle(rawTitle)

        let label: String
        let subtitle: String
        if !cleanArtist.isEmpty {
            label    = cleanArtist
            subtitle = cleanTitle
        } else if !cleanTitle.isEmpty {
            label    = cleanTitle
            subtitle = ""
        } else {
            label    = event.displayName
            subtitle = ""
        }

        self.view?.activate(label: label, subtitle: subtitle)
        HistoryStore.shared.add(event)
        let dismiss = Timer(timeInterval: self.settings.alertDuration, repeats: false) { [weak self] _ in
            self?.view?.deactivate()
        }
        RunLoop.main.add(dismiss, forMode: .common)
        self.alertTimer = dismiss
    }

    func addToHistory(_ event: TrackEvent) {
        HistoryStore.shared.add(event)
    }

    func clearHistory() {
        alertTimer?.invalidate()
        view?.deactivate()
    }
}

final class CirclePanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override var isReleasedWhenClosed: Bool { get { false } set {} }
}

final class PersistentCircleView: NSView {
    var settings: SettingsModel
    var onDragEnd: (() -> Void)?

    private var isActive      = false
    private var isHovered     = false
    private var labelText     = ""
    private var subText       = ""
    private var dragOffset    = NSPoint.zero
    private var overrideColor: NSColor? = nil

    private var glowPhase: CGFloat = 0
    private var glowTimer: Timer?
    private var fillAlpha: CGFloat = 0

    func activate(label: String, subtitle: String) {
        activateWithColor(label: label, subtitle: subtitle, color: nil)
    }

    func activateWithColor(label: String, subtitle: String, color: NSColor?) {
        overrideColor = color
        isActive      = true
        labelText     = label
        subText       = subtitle
        fillAlpha     = 0

        var step = 0
        let t = Timer(timeInterval: 0.016, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            step += 1
            self.fillAlpha = min(1, CGFloat(step) / 20)
            self.display()
            if step >= 20 { timer.invalidate() }
        }
        RunLoop.main.add(t, forMode: .common)

        glowTimer?.invalidate()
        glowPhase = 0
        let g = Timer(timeInterval: 0.033, repeats: true) { [weak self] _ in
            guard let self, self.isActive else { return }
            self.glowPhase += 0.08
            self.display()
        }
        RunLoop.main.add(g, forMode: .common)
        glowTimer = g
    }

    init(frame: NSRect, settings: SettingsModel) {
        self.settings = settings
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isOpaque: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        dragOffset = event.locationInWindow
        NSCursor.closedHand.push()
        isHovered = true
        display()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let win = window else { return }
        let loc = event.locationInWindow
        let dx = loc.x - dragOffset.x
        let dy = loc.y - dragOffset.y
        var f = win.frame
        f.origin.x += dx
        f.origin.y += dy
        win.setFrameOrigin(f.origin)
    }

    override func mouseUp(with event: NSEvent) {
        NSCursor.pop()
        isHovered = false
        display()
        onDragEnd?()
    }

    func deactivate() {
        glowTimer?.invalidate()
        glowTimer   = nil
        isActive    = false
        overrideColor = nil  // zurück zur Settings-Farbe
        var step = 0
        let t = Timer(timeInterval: 0.016, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            step += 1
            self.fillAlpha = max(0, 1 - CGFloat(step) / 20)
            self.display()
            if step >= 20 { timer.invalidate() }
        }
        RunLoop.main.add(t, forMode: .common)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        bounds.fill()

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let size = bounds.width
        let center = CGPoint(x: size / 2, y: size / 2)
        let radius = size / 2 - 4
        let color    = overrideColor
                    ?? (NSColor(settings.alertColor).usingColorSpace(.sRGB) ?? .systemRed)
        let txtColor = (NSColor(settings.alertTextColor).usingColorSpace(.sRGB) ?? .white)

        if isActive {
            let glow = 20 + 16 * abs(sin(glowPhase))
            ctx.setShadow(offset: .zero, blur: glow, color: color.withAlphaComponent(0.8).cgColor)
        }

        let fillColor = color.withAlphaComponent(fillAlpha * 0.92)
        fillColor.setFill()
        let circlePath = NSBezierPath(
            ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        )
        circlePath.fill()

        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        let outlineAlpha: CGFloat = isActive ? 0 : (isHovered ? 0.7 : 0.3)
        let outlineWidth: CGFloat = isHovered ? 3.5 : 2.0
        color.withAlphaComponent(outlineAlpha).setStroke()
        circlePath.lineWidth = outlineWidth
        circlePath.stroke()

        if !isActive {
            let dotR: CGFloat = isHovered ? 5 : 3
            let dotPath = NSBezierPath(
                ovalIn: NSRect(x: center.x - dotR, y: center.y - dotR, width: dotR * 2, height: dotR * 2)
            )
            color.withAlphaComponent(outlineAlpha * 0.8).setFill()
            dotPath.fill()
        }

        if isActive && fillAlpha > 0.3 {
            drawCenteredText(ctx: ctx, size: size, txtColor: txtColor)
        }
    }

    private func drawCenteredText(ctx: CGContext, size: CGFloat, txtColor: NSColor) {
        let pad: CGFloat = 20
        let w = size - pad * 2
        let mid = size / 2
        let fs = settings.fontSize

        let para = NSMutableParagraphStyle()
        para.alignment = .center

        func measure(_ s: NSAttributedString) -> CGFloat {
            s.boundingRect(with: NSSize(width: w, height: 300), options: [.usesLineFragmentOrigin]).height.rounded(.up)
        }

        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: txtColor.withAlphaComponent(0.55),
            .kern: 1.8 as NSNumber,
            .paragraphStyle: para
        ]
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: fs),
            .foregroundColor: txtColor,
            .paragraphStyle: para
        ]
        let subAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: max(11, fs * 0.52)),
            .foregroundColor: txtColor.withAlphaComponent(0.75),
            .paragraphStyle: para
        ]

        let labelStr = NSAttributedString(string: t("circle.alreadyPlayed"), attributes: labelAttr)
        let titleStr = NSAttributedString(string: labelText, attributes: titleAttr)
        let subStr = subText.isEmpty ? nil : NSAttributedString(string: subText, attributes: subAttr)

        let lh = measure(labelStr)
        let th = measure(titleStr)
        let sh = subStr.map { measure($0) } ?? 0
        let gap: CGFloat = 5
        var total = lh + gap + th
        if sh > 0 { total += gap + sh }

        var y = mid - total / 2

        if let s = subStr {
            s.draw(with: NSRect(x: pad, y: y, width: w, height: sh), options: [.usesLineFragmentOrigin])
            y += sh + gap
        }
        titleStr.draw(with: NSRect(x: pad, y: y, width: w, height: th), options: [.usesLineFragmentOrigin])
        y += th + gap
        labelStr.draw(with: NSRect(x: pad, y: y, width: w, height: lh), options: [.usesLineFragmentOrigin])
    }
}

final class BackendController {
    private var process: Process?
    private let settings: SettingsModel

    init(settings: SettingsModel) {
        self.settings = settings
    }

    func start() {
        killOrphanOnPort(settings.wsPort)

        let installer = DependencyInstaller()
        guard let python = installer.findPython() else {
            DispatchQueue.main.async {
                let a = NSAlert()
                a.messageText = "Python 3.11+ nicht gefunden"
                a.informativeText = """
                \(t("install.needsPython"))

                Installieren mit:
                brew install python3

                Dann DjGuard neu starten.
                """
                a.alertStyle = .critical
                a.addButton(withTitle: "OK")
                a.runModal()
            }
            NSLog("DjGuard: python 3.11+ not found")
            return
        }
        NSLog("DjGuard: using python at %@", python)

        guard let script = Bundle.main.path(forResource: "serato_guard", ofType: "py") else {
            NSLog("DjGuard: serato_guard.py not in bundle")
            return
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: python)
        p.arguments = [script]

        var env = ProcessInfo.processInfo.environment
        env["SERATO_GUARD_PORT"] = "\(settings.wsPort)"
        env["SERATO_GUARD_THRESHOLD"] = "\(settings.matchThreshold)"
        p.environment = env

        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { h in
            let data = h.availableData
            guard !data.isEmpty,
                  let s = String(data: data, encoding: .utf8),
                  !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            NSLog("[PY] %@", s.trimmingCharacters(in: .newlines))
        }

        p.terminationHandler = { [weak self] proc in
            guard let self, proc.terminationStatus != 0 else { return }
            NSLog("DjGuard: backend exited (status %d), restarting in 2s...", proc.terminationStatus)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.start()
            }
        }

        do {
            try p.run()
            process = p
            NSLog("DjGuard: backend started (PID %d)", p.processIdentifier)
        } catch {
            NSLog("DjGuard: backend start failed: %@", error.localizedDescription)
        }
    }

    func stop() {
        guard let p = process else { return }
        p.terminationHandler = nil
        p.terminate()
        DispatchQueue.global().async { p.waitUntilExit() }
        process = nil
    }

    private func killOrphanOnPort(_ port: Int) {
        let lsof = Process()
        lsof.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        lsof.arguments = ["-ti", "tcp:\(port)"]
        let pipe = Pipe()
        lsof.standardOutput = pipe
        lsof.standardError = FileHandle.nullDevice
        try? lsof.run()
        lsof.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        for pidStr in out.components(separatedBy: .newlines) {
            let pid = pidStr.trimmingCharacters(in: .whitespaces)
            guard !pid.isEmpty, let pidInt = Int32(pid) else { continue }
            kill(pidInt, SIGTERM)
            NSLog("DjGuard: killed orphan PID %d on port %d", pidInt, port)
        }
        if !out.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
}

final class ConnectWindow: NSObject {
    static func show(settings: SettingsModel, completion: @escaping (String, Int) -> Void) {
        let alert = NSAlert()
        alert.messageText = t("menu.connectDJ")
        alert.informativeText = """
        IP-Adresse des anderen DJ-Laptops eingeben.
        \(t("connect.hint"))
        """
        alert.addButton(withTitle: "Verbinden")
        alert.addButton(withTitle: "Abbrechen")

        let stack = NSStackView(frame: NSRect(x: 0, y: 0, width: 300, height: 60))
        stack.orientation = .vertical
        stack.spacing = 8

        let ipField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 28))
        ipField.placeholderString = "192.168.1.xxx"
        ipField.font = .monospacedSystemFont(ofSize: 14, weight: .regular)

        let hint = NSTextField(labelWithString: "Port wird automatisch übernommen (\(settings.wsPort))")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor

        stack.addArrangedSubview(ipField)
        stack.addArrangedSubview(hint)
        alert.accessoryView = stack

        if alert.runModal() == .alertFirstButtonReturn {
            let ip = ipField.stringValue.trimmingCharacters(in: .whitespaces)
            if !ip.isEmpty { completion(ip, settings.wsPort) }
        }
    }
}

final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    @Published var items: [HistoryItem] = []

    struct HistoryItem: Identifiable {
        let id = UUID()
        let artist: String
        let title: String
        let display: String
        let isDup: Bool
        let time: Date
    }

    func add(_ event: TrackEvent) {
        DispatchQueue.main.async {
            self.items.insert(
                HistoryItem(
                    artist: event.artist,
                    title: event.title,
                    display: event.displayName,
                    isDup: event.isDuplicate,
                    time: Date()
                ),
                at: 0
            )
            if self.items.count > 500 { self.items.removeLast() }
        }
    }

    func clear() {
        DispatchQueue.main.async { self.items.removeAll() }
    }
}

final class HistoryWindowController: NSObject, NSWindowDelegate {
    private static var instance: HistoryWindowController?
    private var windowController: NSWindowController?

    static func show() {
        if let existing = instance, let w = existing.windowController?.window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let ctrl = HistoryWindowController()
        instance = ctrl
        ctrl.open()
    }

    private func open() {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 640),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = "DjGuard – History"
        w.center()
        w.delegate = self
        w.minSize = NSSize(width: 400, height: 400)
        w.contentView = NSHostingView(rootView: HistoryView())
        windowController = NSWindowController(window: w)
        windowController?.showWindow(nil)
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        HistoryWindowController.instance = nil
    }
}

struct HistoryView: View {
    @ObservedObject private var store = HistoryStore.shared
    @State private var search = ""

    private var filtered: [HistoryStore.HistoryItem] {
        if search.isEmpty { return store.items }
        let q = search.lowercased()
        return store.items.filter {
            $0.artist.lowercased().contains(q) ||
            $0.title.lowercased().contains(q) ||
            $0.display.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(t("history.search"), text: $search)
                    .textFieldStyle(.plain)
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(.regularMaterial)

            Divider()

            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: store.items.isEmpty ? "music.note.list" : "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text(store.items.isEmpty ? t("history.empty") : t("history.noResults"))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filtered) { item in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(item.isDup ? Color.red : Color.clear)
                            .frame(width: 3, height: 40)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.artist.isEmpty ? item.display : item.artist)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            if !item.title.isEmpty && !item.artist.isEmpty {
                                Text(item.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            if item.isDup {
                                Text(t("history.duplicate"))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.12))
                                    .cornerRadius(4)
                            }
                            Text(item.time, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
            }

            Divider()

            HStack {
                Text("\(filtered.count) Track\(filtered.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(t("history.clearSession")) {
                    HistoryStore.shared.clear()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

final class ClientListWindow: NSObject, NSWindowDelegate {
    private static var instance: ClientListWindow?
    private var windowController: NSWindowController?

    static func show(clients: [[String: Any]]) {
        let win = ClientListWindow()
        instance = win
        win.open(clients: clients)
    }

    private func open(clients: [[String: Any]]) {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 340),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = t("clients.title")
        w.minSize = NSSize(width: 360, height: 240)
        w.center()
        w.delegate = self
        w.contentView = NSHostingView(rootView: ClientListView(clients: clients))

        windowController = NSWindowController(window: w)
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        ClientListWindow.instance = nil
    }
}

struct ClientListView: View {
    let clients: [[String: Any]]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if clients.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("Keine Verbindungen")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(clients.indices, id: \.self) { i in
                    let c = clients[i]
                    HStack(spacing: 12) {
                        Image(systemName: (c["is_peer"] as? Bool == true) ? "desktopcomputer" : "iphone")
                            .foregroundStyle(.tint)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(c["name"] as? String ?? "Unbekannt").fontWeight(.medium)
                            Text(c["ip"] as? String ?? "").font(.caption).foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(c["connected_since"] as? String ?? "")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if c["is_peer"] as? Bool == true {
                                Text("DJ Guard")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.tint.opacity(0.15))
                                    .cornerRadius(4)
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

final class ProgressWindow {
    private var window: NSWindow?
    private static var shared: ProgressWindow?

    static func show(message: String, work: @escaping (@escaping () -> Void) -> Void) {
        let pw = ProgressWindow()
        shared = pw
        pw.display(message: message, work: work)
    }

    private func display(message: String, work: @escaping (@escaping () -> Void) -> Void) {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 120),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        w.title = "DjGuard – Setup"
        w.center()
        w.isReleasedWhenClosed = false
        window = w

        let container = NSView(frame: w.contentView!.bounds)

        let indicator = NSProgressIndicator(frame: NSRect(x: 24, y: 68, width: 20, height: 20))
        indicator.style = .spinning
        indicator.controlSize = .small
        indicator.startAnimation(nil)

        let label = NSTextField(labelWithString: message)
        label.frame = NSRect(x: 52, y: 70, width: 290, height: 18)
        label.font = .systemFont(ofSize: 13, weight: .medium)

        let sub = NSTextField(labelWithString: "Bitte warten, dies kann 1–2 Minuten dauern…")
        sub.frame = NSRect(x: 24, y: 40, width: 316, height: 16)
        sub.font = .systemFont(ofSize: 11)
        sub.textColor = .secondaryLabelColor

        let bar = NSProgressIndicator(frame: NSRect(x: 24, y: 16, width: 316, height: 8))
        bar.style = .bar
        bar.isIndeterminate = true
        bar.startAnimation(nil)

        [indicator, label, sub, bar].forEach { container.addSubview($0) }
        w.contentView?.addSubview(container)
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.global(qos: .userInitiated).async {
            work {
                DispatchQueue.main.async { [weak self] in
                    self?.window?.close()
                    self?.window = nil
                    ProgressWindow.shared = nil
                }
            }
        }
    }
}

final class SettingsWindowController: NSObject, NSWindowDelegate {
    private static var instance: SettingsWindowController?
    private var windowController: NSWindowController?

    static func show(settings: SettingsModel) {
        if let existing = instance, let w = existing.windowController?.window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let ctrl = SettingsWindowController()
        instance = ctrl
        ctrl.open(settings: settings)
    }

    // Fenster neu aufbauen wenn Sprache geändert wird
    static func reload() {
        guard let inst = instance else { return }
        guard let delegate = NSApp.delegate as? AppDelegate else { return }
        inst.windowController?.window?.close()
        instance = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            SettingsWindowController.show(settings: delegate.settings)
        }
    }

    private func open(settings: SettingsModel) {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 590),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = t("settings.title")
        w.center()
        w.delegate = self
        w.level = .floating
        w.contentView = NSHostingView(rootView: SettingsRootView(model: settings))

        windowController = NSWindowController(window: w)
        windowController?.showWindow(nil)
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        SettingsWindowController.instance = nil
    }
}

struct SettingsRootView: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        TabView {
            VisualTab(m: model)
                .tabItem { Label(t("tab.appearance"), systemImage: "paintbrush") }
            MatchingTab(m: model)
                .tabItem { Label(t("tab.matching"), systemImage: "waveform.and.magnifyingglass") }
            VenueTab(m: model)
                .tabItem { Label(t("tab.venue"), systemImage: "mappin.circle") }
            NetworkTab(m: model)
                .tabItem { Label(t("tab.network"), systemImage: "network") }
        }
        .frame(width: 520, height: 560)
    }
}

struct VisualTab: View {
    @ObservedObject var m: SettingsModel
    @State private var testFired = false

    var body: some View {
        Form {
            Section(t("appearance.alertBubble")) {
                ColorPicker(t("appearance.bgColor"), selection: $m.alertColor)
                ColorPicker(t("appearance.textColor"), selection: $m.alertTextColor)
                slider(t("appearance.size"), $m.alertSize, 160, 500, "pt")
                slider(t("appearance.fontSize"), $m.fontSize, 14, 60, "pt")
                slider(t("appearance.duration"), $m.alertDuration, 2, 30, "s")
                slider(t("appearance.opacity"), $m.backgroundOpacity, 0.3, 1.0, "%", scale: 100)
            }

            Section(t("appearance.preview")) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(m.alertColor)
                            .frame(width: 52, height: 52)
                            .shadow(color: m.alertColor.opacity(0.6), radius: 8)
                        VStack(spacing: 1) {
                            Text("Calvin")
                                .font(.system(size: m.fontSize * 0.22, weight: .bold))
                                .foregroundColor(m.alertTextColor)
                            Text("Harris")
                                .font(.system(size: m.fontSize * 0.18))
                                .foregroundColor(m.alertTextColor.opacity(0.75))
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(t("appearance.preview"))
                            .font(.headline)
                        Text(t("appearance.previewSub"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(testFired ? t("appearance.testSent") : t("appearance.testAlert")) {
                        fireTestAlert()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(testFired ? .green : .accentColor)
                    .disabled(testFired)
                }
                .padding(.vertical, 4)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(t("appearance.resetPos"))
                            .font(.subheadline)
                        Text(t("appearance.resetPosSub"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(t("appearance.center")) {
                        resetCirclePosition()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 2)
            }

            Section(t("appearance.language")) {
                Picker("", selection: Binding(
                    get: { L.shared.lang },
                    set: { L.shared.set($0) }
                )) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
            }

        }
        .formStyle(.grouped)
        .padding()
    }

    private func resetCirclePosition() {
        NotificationCenter.default.post(
            name: NSNotification.Name("DjGuardResetCirclePosition"), object: nil
        )
    }

    private func fireTestAlert() {
        testFired = true
        NotificationCenter.default.post(name: NSNotification.Name("DjGuardTestAlert"), object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.testFired = false
        }
    }

    func slider(
        _ label: String,
        _ value: Binding<Double>,
        _ lo: Double,
        _ hi: Double,
        _ unit: String,
        scale: Double = 1
    ) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: lo...hi, step: unit == "s" ? 1 : (unit == "pt" ? 2 : 0.05))
            Text(scale == 100 ? "\(Int(value.wrappedValue * scale))%" : "\(Int(value.wrappedValue))\(unit)")
                .monospacedDigit()
                .frame(width: 48)
        }
    }
}

struct MatchingTab: View {
    @ObservedObject var m: SettingsModel

    var body: some View {
        Form {
            Section(t("matching.threshold")) {
                HStack {
                    Slider(value: Binding(
                        get: { Double(m.matchThreshold) },
                        set: { m.matchThreshold = Int($0) }
                    ), in: 60...99, step: 1)
                    Text("\(m.matchThreshold)%").monospacedDigit().frame(width: 40)
                }
                Text(t("matching.recommended"))
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section(t("matching.minPlay")) {
                HStack {
                    Slider(value: Binding(
                        get: { Double(m.minPlaySeconds) },
                        set: { m.minPlaySeconds = Int($0) }
                    ), in: 5...60, step: 5)
                    Text("\(m.minPlaySeconds)s").monospacedDigit().frame(width: 40)
                }
                Text(t("matching.minPlaySub"))
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section(t("matching.timeWindow")) {
                Picker(t("matching.mode"), selection: $m.windowMode) {
                    Text(t("matching.since")).tag("session")
                    Text(t("matching.lastHours")).tag("hours")
                }
                .pickerStyle(.radioGroup)

                if m.windowMode == "hours" {
                    HStack {
                        Text("Zeitfenster")
                        Slider(value: $m.windowHours, in: 1...24, step: 1)
                        Text("\(Int(m.windowHours))h").monospacedDigit().frame(width: 36)
                    }
                    Text("Tracks die vor mehr als \(Int(m.windowHours))h gespielt wurden, werden ignoriert.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct VenueTab: View {
    @ObservedObject var m: SettingsModel

    var body: some View {
        Form {
            Section(t("venue.location")) {
                TextField(t("venue.nameLabel"), text: $m.venueName)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text("ID").foregroundStyle(.secondary)
                    Text(m.venueId).font(.caption).monospaced().foregroundStyle(.secondary)
                    Spacer()
                    Button(t("venue.newIDBtn")) {
                        m.venueId = SettingsModel.defaultVenueId() + "_\(Int.random(in: 100...999))"
                    }
                    .buttonStyle(.bordered)
                }

                Text(t("venue.isolation"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct NetworkTab: View {
    @ObservedObject var m: SettingsModel
    @State private var localIP = "wird geladen…"

    var body: some View {
        Form {
            Section(t("network.thisDevice")) {
                TextField(t("network.visibleName"), text: $m.nodeName)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text(t("network.ipAddress"))
                    Spacer()
                    Text(localIP).monospaced().foregroundStyle(.tint).textSelection(.enabled)
                }

                HStack {
                    Text("Port")
                    Spacer()
                    TextField(t("network.port"), value: $m.wsPort, format: .number)
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section(t("connect.otherDJs")) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle").foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(t("network.wlanInfo"))
                            .fontWeight(.medium)
                        Text(t("network.noWlan"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text(t("network.yourAddress"))
                    Spacer()
                    Text("\(localIP):\(m.wsPort)").monospaced().foregroundStyle(.tint).textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear { localIP = getLocalIP() }
    }

    func getLocalIP() -> String {
        var addr = "127.0.0.1"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let base = ifaddr else { return addr }
        var ptr = base
        defer { freeifaddrs(ifaddr) }

        while true {
            let iface = ptr.pointee
            if iface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: iface.ifa_name)
                if name == "en0" || name == "en1" {
                    var h = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        iface.ifa_addr,
                        socklen_t(iface.ifa_addr.pointee.sa_len),
                        &h,
                        socklen_t(h.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                    addr = String(cString: h)
                }
            }
            if let next = iface.ifa_next { ptr = next } else { break }
        }
        return addr
    }
}

extension NSImage {
    func tinted(_ color: NSColor) -> NSImage {
        let copy = self.copy() as! NSImage
        copy.lockFocus()
        color.set()
        NSRect(origin: .zero, size: copy.size).fill(using: .sourceAtop)
        copy.unlockFocus()
        return copy
    }
}
