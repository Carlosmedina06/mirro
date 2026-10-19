import Foundation

// MARK: - Modelo

struct AndroidDevice: Identifiable, Hashable {
    let serial: String
    let state: String      // device, unauthorized, offline...
    let model: String

    var id: String { serial }
    var isReady: Bool { state == "device" }
    var isWireless: Bool { serial.contains(":") || serial.contains("adb-tls-connect") }
}

struct DeviceDetails: Hashable {
    var manufacturer = ""
    var androidVersion = ""
    var battery: Int?
}

// MARK: - Utilidades de shell

enum Tools {
    private(set) static var adb: String?
    private(set) static var scrcpy: String?
    /// Lo que scrcpy sube y ejecuta en el teléfono
    private(set) static var scrcpyServer: String?
    /// Carpeta con los binarios de scrcpy empaquetados en Mirro.app
    static let bundledBin = Bundle.main.resourceURL!.appendingPathComponent("bin").path

    static func refresh() {
        func bundled(_ name: String) -> String? {
            let p = "\(bundledBin)/\(name)"
            return FileManager.default.fileExists(atPath: p) ? p : nil
        }
        scrcpy = bundled("scrcpy")
        scrcpyServer = bundled("scrcpy-server")

        // Si ya tienes adb (Android Studio, Homebrew) usamos ese: dos versiones distintas
        // se pelean por el servidor adb y se reinician mutuamente.
        var extra: [String] = []
        if let sdk = ProcessInfo.processInfo.environment["ANDROID_HOME"] {
            extra.append("\(sdk)/platform-tools/adb")
        }
        adb = find("adb", extra: extra) ?? bundled("adb")
    }

    /// Las apps lanzadas desde Finder no heredan el PATH de la terminal,
    /// así que buscamos los binarios en las rutas habituales.
    static func find(_ name: String, extra: [String] = []) -> String? {
        let home = NSHomeDirectory()
        let candidates = extra + [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "\(home)/Library/Android/sdk/platform-tools/\(name)",
            "/usr/bin/\(name)",
        ]
        if let hit = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return hit
        }
        // Último recurso: preguntar a un login shell
        let out = run("/bin/zsh", ["-lc", "command -v \(name)"])
        let path = out.trimmingCharacters(in: .whitespacesAndNewlines)
        return path.hasPrefix("/") ? path : nil
    }

    @discardableResult
    static func run(_ launchPath: String, _ args: [String]) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: launchPath)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        p.standardInput = FileHandle.nullDevice
        do { try p.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func listDevices() -> [AndroidDevice] {
        guard let adb else { return [] }
        let out = run(adb, ["devices", "-l"])
        return out.split(separator: "\n").drop(while: { !$0.hasPrefix("List of devices") }).dropFirst().compactMap { line in
            let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard parts.count >= 2 else { return nil }
            let model = parts.first(where: { $0.hasPrefix("model:") })?
                .replacingOccurrences(of: "model:", with: "")
                .replacingOccurrences(of: "_", with: " ") ?? parts[0]
            return AndroidDevice(serial: parts[0], state: parts[1], model: model)
        }
    }

    static func details(_ serial: String) -> DeviceDetails {
        guard let adb else { return DeviceDetails() }
        let out = run(adb, ["-s", serial, "shell",
                            "getprop ro.product.manufacturer; getprop ro.build.version.release; dumpsys battery | grep -m1 level"])
        let lines = out.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var d = DeviceDetails()
        if lines.count > 0 { d.manufacturer = lines[0].capitalized }
        if lines.count > 1 { d.androidVersion = lines[1] }
        if lines.count > 2 { d.battery = Int(lines[2].replacingOccurrences(of: "level:", with: "").trimmingCharacters(in: .whitespaces)) }
        return d
    }

    /// Pasa un dispositivo USB a modo adb por WiFi y se conecta a él.
    static func enableWiFi(_ serial: String) -> String {
        guard let adb else { return "adb no encontrado" }
        let route = run(adb, ["-s", serial, "shell", "ip route"])
        var ip: String?
        for line in route.split(separator: "\n") where line.contains("wlan") {
            let tokens = line.split(separator: " ").map(String.init)
            if let i = tokens.firstIndex(of: "src"), i + 1 < tokens.count { ip = tokens[i + 1]; break }
        }
        guard let ip else { return "El teléfono no está conectado a una red WiFi" }
        run(adb, ["-s", serial, "tcpip", "5555"])
        Thread.sleep(forTimeInterval: 2)
        return connect("\(ip):5555")
    }

    static func connect(_ address: String) -> String {
        guard let adb else { return "adb no encontrado" }
        return run(adb, ["connect", address]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func disconnect(_ serial: String) -> String {
        guard let adb else { return "adb no encontrado" }
        return run(adb, ["disconnect", serial]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
