import SwiftUI
import AppKit

struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Group {
            if !model.toolsChecked {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !model.toolsReady {
                BrokenBundleView()
            } else if !model.setupDone {
                OnboardingView(model: model)
            } else {
                DevicesView(model: model)
            }
        }
        .frame(minWidth: 580, minHeight: 580)
        .tint(.brand)
    }
}

extension Color {
    /// Verde del icono de la app
    static let brand = Color(red: 0.06, green: 0.62, blue: 0.47)
}

// MARK: - Onboarding

struct OnboardingView: View {
    @ObservedObject var model: AppModel
    @State private var step: Step

    enum Step: Int, CaseIterable { case welcome, phone }

    init(model: AppModel) {
        self.model = model
        _step = State(initialValue: .welcome)
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch step {
                case .welcome: WelcomeStep()
                case .phone:   PhoneStep(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(36)

            Divider()
            HStack {
                HStack(spacing: 6) {
                    ForEach(Step.allCases, id: \.self) { s in
                        Circle()
                            .fill(s == step ? Color.brand : Color.secondary.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }
                Spacer()
                if step != .welcome {
                    Button("Atrás") { step = Step(rawValue: step.rawValue - 1)! }
                }
                primaryButton
            }
            .padding(16)
        }
    }

    @ViewBuilder private var primaryButton: some View {
        switch step {
        case .welcome:
            Button("Comenzar") { step = .phone }
                .keyboardShortcut(.defaultAction)
        case .phone:
            Button(model.devices.contains(where: \.isReady) ? "Terminar" : "Omitir por ahora") {
                model.setupDone = true
            }
            .keyboardShortcut(.defaultAction)
        }
    }
}

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
            Text("Bienvenido a Mirro")
                .font(.largeTitle.bold())
            Text("Duplica y controla tus teléfonos Android desde la Mac.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 14) {
                Feature(icon: "rectangle.on.rectangle", text: "Ve y usa la pantalla del teléfono en una ventana")
                Feature(icon: "cable.connector", text: "Por USB o WiFi, con varios dispositivos a la vez")
                Feature(icon: "menubar.rectangle", text: "Siempre a mano desde la barra de estado")
            }
            .padding(.top, 12)
        }
    }

    private struct Feature: View {
        let icon: String, text: String
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.brand)
                    .frame(width: 28)
                Text(text)
            }
        }
    }
}

/// Solo aparece si faltan los binarios dentro de Mirro.app (p. ej. una build incompleta).
private struct BrokenBundleView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("Mirro está incompleta").font(.title2.bold())
            Text("No se encontró scrcpy dentro de la app. Vuelve a compilarla con ./build.sh o descárgala de nuevo.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PhoneStep: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Prepara tu teléfono").font(.title.bold())
                Text("Solo hay que hacerlo una vez por dispositivo.")
                    .foregroundStyle(.secondary)
            }
            PhoneSetupSteps()
            Spacer(minLength: 0)
            DetectionStatus(devices: model.devices)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PhoneSetupSteps: View {
    private let steps = [
        "Abre **Ajustes › Acerca del teléfono** y toca 7 veces **Número de compilación** para activar las opciones de desarrollador.",
        "Ve a **Ajustes › Sistema › Opciones de desarrollador** y activa **Depuración USB**.",
        "Conecta el teléfono a la Mac con un cable USB.",
        "En el teléfono, acepta **¿Permitir depuración USB?** y marca «Permitir siempre desde esta computadora».",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.callout.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.brand))
                    Text(.init(s))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct DetectionStatus: View {
    let devices: [AndroidDevice]

    var body: some View {
        HStack(spacing: 10) {
            if let d = devices.first(where: \.isReady) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("**\(d.model)** conectado. ¡Todo listo!")
            } else if devices.contains(where: { $0.state == "unauthorized" }) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                Text("Teléfono detectado: acepta el aviso de depuración USB en la pantalla.")
            } else {
                ProgressView().controlSize(.small)
                Text("Esperando un dispositivo…").foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(nsColor: .separatorColor)))
    }
}

// MARK: - Lista de dispositivos

struct DevicesView: View {
    @ObservedObject var model: AppModel
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var address = ""

    private var readyCount: Int { model.devices.filter(\.isReady).count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if model.devices.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(model.devices) { d in
                            DeviceRow(model: model, device: d, details: model.details[d.serial],
                                      isRunning: model.running.contains(d.serial))
                        }
                    }
                    .padding(20)
                }
            }
            Divider()
            footer
        }
        .overlay(alignment: .bottom) {
            if let toast = model.toast {
                Text(toast)
                    .font(.callout)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 4, y: 2)
                    .padding(.bottom, 70)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.toast)
        .sheet(isPresented: $showSettings) { SettingsView(model: model) }
        .sheet(isPresented: $showHelp) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Conectar un teléfono").font(.title2.bold())
                PhoneSetupSteps()
                HStack { Spacer(); Button("Cerrar") { showHelp = false }.keyboardShortcut(.defaultAction) }
            }
            .padding(24)
            .frame(width: 460)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dispositivos").font(.title2.bold())
                Text(subtitle).font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            if !model.running.isEmpty {
                Button("Detener todos") { model.stopAll() }
            }
            if readyCount > 1 {
                Button("Duplicar todos") { model.mirrorAll() }
            }
            Button { model.refreshDevices(full: true) } label: { Image(systemName: "arrow.clockwise") }
                .help("Actualizar")
            Button { showSettings = true } label: { Image(systemName: "gearshape") }
                .help("Ajustes")
        }
        .padding(20)
    }

    private var subtitle: String {
        let n = model.devices.count
        let base = n == 0 ? "Ninguno conectado" : n == 1 ? "1 conectado" : "\(n) conectados"
        return model.running.isEmpty ? base : "\(base) · \(model.running.count) duplicando"
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "smartphone")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(.secondary)
            Text("Conecta un teléfono").font(.title3.bold())
            Text("Conéctalo por USB con la depuración USB activada,\no escribe su IP abajo para conectarte por WiFi.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("¿Cómo activo la depuración USB?") { showHelp = true }
                .buttonStyle(.link)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi").foregroundStyle(.secondary)
            TextField("IP del teléfono (ej. 192.168.1.20:5555)", text: $address)
                .textFieldStyle(.roundedBorder)
                .onSubmit(connect)
            Button("Conectar", action: connect)
                .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
    }

    private func connect() {
        model.connect(address)
        address = ""
    }
}

private struct DeviceRow: View {
    @ObservedObject var model: AppModel
    let device: AndroidDevice
    let details: DeviceDetails?
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isRunning ? Color.brand.opacity(0.15) : Color.secondary.opacity(0.1))
                Image(systemName: device.isWireless ? "wifi" : "cable.connector")
                    .font(.title3)
                    .foregroundStyle(isRunning ? Color.brand : Color.secondary)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(device.model).font(.headline)
                    if isRunning {
                        Text("Duplicando")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.18)))
                            .foregroundStyle(.green)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
            }

            Spacer()

            switch device.state {
            case "device":
                Button(isRunning ? "Detener" : "Duplicar") { model.toggle(device) }
                    .buttonStyle(.borderedProminent)
                    .tint(isRunning ? .red : .brand)
                Menu {
                    if device.isWireless {
                        Button("Desconectar") { model.disconnect(device) }
                    } else {
                        Button("Activar conexión WiFi") { model.enableWiFi(device) }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            case "unauthorized":
                Label("Acepta la depuración en el teléfono", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            default:
                Text(device.state.capitalized).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(nsColor: .separatorColor)))
    }

    private var subtitle: String {
        var parts: [String] = []
        if let d = details {
            if !d.manufacturer.isEmpty { parts.append(d.manufacturer) }
            if !d.androidVersion.isEmpty { parts.append("Android \(d.androidVersion)") }
            if let b = d.battery { parts.append("Batería \(b)%") }
        }
        parts.append(device.serial)
        return parts.joined(separator: " · ")
    }
}

// MARK: - Ajustes

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Prefs.maxSize) private var maxSize = 0
    @AppStorage(Prefs.showWindowOnLaunch) private var showWindowOnLaunch = true

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Duplicación") {
                    ForEach(Option.allCases) { OptionToggle(option: $0) }
                    Picker("Resolución máxima", selection: $maxSize) {
                        Text("Original").tag(0)
                        Text("1024 px").tag(1024)
                        Text("1600 px").tag(1600)
                        Text("1920 px").tag(1920)
                    }
                }
                Section("General") {
                    Toggle("Abrir al iniciar sesión", isOn: $model.launchAtLogin)
                    Toggle("Mostrar esta ventana al abrir Mirro", isOn: $showWindowOnLaunch)
                    Button("Repetir configuración inicial") {
                        dismiss()
                        model.setupDone = false
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Listo") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 440, height: 500)
    }
}

private struct OptionToggle: View {
    let option: Option
    @AppStorage private var isOn: Bool

    init(option: Option) {
        self.option = option
        _isOn = AppStorage(wrappedValue: false, option.rawValue)
    }

    var body: some View {
        Toggle(option.title, isOn: $isOn)
    }
}
