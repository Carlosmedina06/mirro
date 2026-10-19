import AppKit
import ServiceManagement

// MARK: - Opciones persistentes

enum Option: String, CaseIterable, Identifiable {
    case turnScreenOff, stayAwake, noAudio, alwaysOnTop, showTouches

    var id: String { rawValue }

    var title: String {
        switch self {
        case .turnScreenOff: return "Apagar pantalla del teléfono"
        case .stayAwake:     return "Mantener despierto"
        case .noAudio:       return "Sin audio"
        case .alwaysOnTop:   return "Ventana siempre encima"
        case .showTouches:   return "Mostrar toques"
        }
    }

    var flag: String {
        switch self {
        case .turnScreenOff: return "--turn-screen-off"
        case .stayAwake:     return "--stay-awake"
        case .noAudio:       return "--no-audio"
        case .alwaysOnTop:   return "--always-on-top"
        case .showTouches:   return "--show-touches"
        }
    }

    var isOn: Bool {
        get { UserDefaults.standard.bool(forKey: rawValue) }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: rawValue) }
    }
}

enum Prefs {
    static let maxSize = "maxSize"
    static let setupDone = "setupDone"
    static let showWindowOnLaunch = "showWindowOnLaunch"
}

func showAlert(_ title: String, _ text: String) {
    NSApp.activate(ignoringOtherApps: true)
    let a = NSAlert()
    a.messageText = title
    a.informativeText = text
    a.runModal()
}

// MARK: - Estado compartido entre la ventana y la barra de estado

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published private(set) var devices: [AndroidDevice] = []
    @Published private(set) var details: [String: DeviceDetails] = [:]
    @Published private(set) var running: Set<String> = []

    @Published private(set) var toolsChecked = false
    @Published private(set) var hasAdb = false
    @Published private(set) var hasScrcpy = false

    @Published var toast: String?
    @Published var setupDone: Bool {
        didSet { UserDefaults.standard.set(setupDone, forKey: Prefs.setupDone) }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != (SMAppService.mainApp.status == .enabled) else { return }
            do {
                if launchAtLogin { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                showAlert("No se pudo cambiar el inicio automático", error.localizedDescription)
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }

    var toolsReady: Bool { hasAdb && hasScrcpy }

    private var sessions: [String: Process] = [:]   // serial -> proceso scrcpy
    private var pollTimer: Timer?
    private var refreshing = false
    private var toastTask: Task<Void, Never>?

    private init() {
        setupDone = UserDefaults.standard.bool(forKey: Prefs.setupDone)
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: Herramientas

    func checkTools() async {
        let found = await Task.detached { () -> (Bool, Bool) in
            Tools.refresh()
            return (Tools.adb != nil, Tools.scrcpy != nil && Tools.scrcpyServer != nil)
        }.value
        (hasAdb, hasScrcpy) = found
        toolsChecked = true
        refreshDevices()
    }

    // MARK: Dispositivos

    func apply(_ list: [AndroidDevice]) {
        if list != devices { devices = list }
        let missing = list.filter { $0.isReady && details[$0.serial] == nil }
        for d in missing {
            details[d.serial] = DeviceDetails()   // marca como pedido
            Task {
                let det = await Task.detached { Tools.details(d.serial) }.value
                self.details[d.serial] = det
            }
        }
    }

    func refreshDevices(full: Bool = false) {
        guard hasAdb, !refreshing else { return }
        if full { details = [:] }
        refreshing = true
        Task {
            let list = await Task.detached { Tools.listDevices() }.value
            refreshing = false
            apply(list)
        }
    }

    func startPolling() {
        guard pollTimer == nil else { return }
        refreshDevices()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            Task { @MainActor in AppModel.shared.refreshDevices() }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func enableWiFi(_ device: AndroidDevice) {
        say("Activando WiFi en \(device.model)…")
        Task {
            let msg = await Task.detached { Tools.enableWiFi(device.serial) }.value
            say(msg)
            refreshDevices()
        }
    }

    func connect(_ address: String) {
        let addr = address.trimmingCharacters(in: .whitespaces)
        guard !addr.isEmpty else { return }
        let full = addr.contains(":") ? addr : "\(addr):5555"
        say("Conectando a \(full)…")
        Task {
            let msg = await Task.detached { Tools.connect(full) }.value
            say(msg)
            refreshDevices()
        }
    }

    func disconnect(_ device: AndroidDevice) {
        stop(device.serial)
        Task {
            let msg = await Task.detached { Tools.disconnect(device.serial) }.value
            say(msg)
            refreshDevices()
        }
    }

    func say(_ text: String) {
        toast = text
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !Task.isCancelled { toast = nil }
        }
    }

    // MARK: Sesiones de scrcpy

    func toggle(_ device: AndroidDevice) {
        if running.contains(device.serial) { stop(device.serial) } else { start(device) }
    }

    func mirrorAll() {
        devices.filter { $0.isReady && !running.contains($0.serial) }.forEach(start)
    }

    func stopAll() {
        sessions.values.forEach { $0.terminate() }
    }

    func stop(_ serial: String) {
        sessions[serial]?.terminate()
    }

    func start(_ device: AndroidDevice) {
        guard let scrcpy = Tools.scrcpy, let adb = Tools.adb else { return }
        let serial = device.serial
        let p = Process()
        p.executableURL = URL(fileURLWithPath: scrcpy)
        var args = ["-s", serial, "--window-title", device.model]
        args += Option.allCases.filter(\.isOn).map(\.flag)
        let maxSize = UserDefaults.standard.integer(forKey: Prefs.maxSize)
        if maxSize > 0 { args += ["--max-size", String(maxSize)] }
        p.arguments = args

        // scrcpy necesita encontrar adb y el servidor que sube al teléfono
        var env = ProcessInfo.processInfo.environment
        env["ADB"] = adb
        env["SCRCPY_SERVER_PATH"] = Tools.scrcpyServer
        env["SCRCPY_ICON_PATH"] = "\(Tools.bundledBin)/scrcpy.png"
        let dirs = [adb, scrcpy].map { URL(fileURLWithPath: $0).deletingLastPathComponent().path }
        env["PATH"] = (dirs + [env["PATH"] ?? "/usr/bin:/bin"]).joined(separator: ":")
        p.environment = env
        p.standardOutput = FileHandle.nullDevice
        p.standardInput = FileHandle.nullDevice

        // Guardamos solo el final del log para no llenar el pipe
        let errPipe = Pipe()
        p.standardError = errPipe
        let log = LogBuffer()
        errPipe.fileHandleForReading.readabilityHandler = { log.append($0.availableData) }

        p.terminationHandler = { proc in
            errPipe.fileHandleForReading.readabilityHandler = nil
            let err = log.text
            Task { @MainActor in
                let m = AppModel.shared
                m.sessions[serial] = nil
                m.running.remove(serial)
                // Código distinto de 0 y no lo matamos nosotros => mostrar error
                if proc.terminationReason == .exit && proc.terminationStatus != 0 && proc.terminationStatus != 2 {
                    let lines = err.split(separator: "\n").filter { $0.contains("ERROR") }.suffix(4)
                    showAlert("scrcpy terminó con error (\(device.model))",
                              lines.isEmpty ? String(err.suffix(400)) : lines.joined(separator: "\n"))
                }
            }
        }

        do {
            try p.run()
            sessions[serial] = p
            running.insert(serial)
        } catch {
            showAlert("No se pudo iniciar scrcpy", error.localizedDescription)
        }
    }
}

final class LogBuffer: @unchecked Sendable {
    private var data = Data()
    private let lock = NSLock()

    func append(_ d: Data) {
        lock.lock(); defer { lock.unlock() }
        data.append(d)
        if data.count > 8192 { data = data.suffix(4096) }
    }

    var text: String {
        lock.lock(); defer { lock.unlock() }
        return String(decoding: data, as: UTF8.self)
    }
}
