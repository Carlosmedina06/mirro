import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private let model = AppModel.shared
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private var window: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [Prefs.showWindowOnLaunch: true])

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu.delegate = self
        statusItem.menu = menu
        updateIcon()
        Publishers.Merge3(model.$running.map { _ in () }, model.$hasAdb.map { _ in () }, model.$hasScrcpy.map { _ in () })
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.updateIcon() }
            .store(in: &cancellables)

        Task { await model.checkTools() }

        if UserDefaults.standard.bool(forKey: Prefs.showWindowOnLaunch) || !model.setupDone {
            showWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.stopAll()
    }

    // Doble clic en la app cuando ya está abierta
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    // MARK: Ventana

    @objc func showWindow() {
        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 640),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable],
                             backing: .buffered, defer: false)
            w.title = "Mirro"
            w.contentViewController = NSHostingController(rootView: RootView(model: model))
            w.setContentSize(NSSize(width: 620, height: 640))
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.center()
            w.setFrameAutosaveName("MirroMain")
            window = w
        }
        // Mientras la ventana está abierta, la app aparece en el Dock y en Cmd+Tab
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        model.startPolling()
    }

    func windowWillClose(_ notification: Notification) {
        model.stopPolling()
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: Barra de estado

    private func updateIcon() {
        let running = model.running.count
        let style: StatusIcon.Style = model.toolsChecked && !model.toolsReady ? .warning
            : running > 0 ? .mirroring : .idle
        statusItem.button?.image = StatusIcon.image(style)
        statusItem.button?.title = running > 1 ? "\(running)" : ""
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.toolTip = running > 0 ? "Mirro — duplicando \(running)" : "Mirro"
    }

    // Se reconstruye cada vez que se abre el menú
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(item("Abrir Mirro…", #selector(showWindow), key: "o"))
        menu.addItem(.separator())

        guard model.toolsReady else {
            menu.addItem(disabled(model.toolsChecked ? "Faltan scrcpy o adb" : "Comprobando herramientas…"))
            menu.addItem(item("Configurar…", #selector(showWindow)))
            menu.addItem(.separator())
            menu.addItem(item("Salir", #selector(quit), key: "q"))
            return
        }

        let devices = Tools.listDevices()
        model.apply(devices)
        menu.addItem(disabled(devices.isEmpty ? "No hay dispositivos conectados" : "Dispositivos"))

        for d in devices {
            let mi: NSMenuItem
            switch d.state {
            case "device":
                mi = item("\(d.model)  ·  \(d.serial)", #selector(toggleDevice(_:)))
                mi.representedObject = d
                mi.state = model.running.contains(d.serial) ? .on : .off
                mi.image = NSImage(systemSymbolName: d.isWireless ? "wifi" : "cable.connector",
                                   accessibilityDescription: nil)
            case "unauthorized":
                mi = disabled("\(d.serial) — acepta la depuración USB en el teléfono")
            default:
                mi = disabled("\(d.serial) — \(d.state)")
            }
            menu.addItem(mi)
        }

        if devices.filter(\.isReady).count > 1 {
            menu.addItem(.separator())
            menu.addItem(item("Duplicar todos", #selector(mirrorAll)))
        }
        if !model.running.isEmpty {
            menu.addItem(item("Detener todos", #selector(stopAll)))
        }

        menu.addItem(.separator())
        let optsItem = NSMenuItem(title: "Opciones", action: nil, keyEquivalent: "")
        let opts = NSMenu()
        for o in Option.allCases {
            let mi = item(o.title, #selector(toggleOption(_:)))
            mi.representedObject = o.rawValue
            mi.state = o.isOn ? .on : .off
            opts.addItem(mi)
        }
        opts.addItem(.separator())
        let login = item("Abrir al iniciar sesión", #selector(toggleLogin))
        login.state = model.launchAtLogin ? .on : .off
        opts.addItem(login)
        optsItem.submenu = opts
        menu.addItem(optsItem)

        menu.addItem(.separator())
        menu.addItem(item("Salir", #selector(quit), key: "q"))
    }

    // MARK: Acciones

    @objc private func toggleDevice(_ sender: NSMenuItem) {
        guard let d = sender.representedObject as? AndroidDevice else { return }
        model.toggle(d)
    }

    @objc private func mirrorAll() { model.mirrorAll() }
    @objc private func stopAll() { model.stopAll() }

    @objc private func toggleOption(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let o = Option(rawValue: raw) else { return }
        o.isOn.toggle()
    }

    @objc private func toggleLogin() { model.launchAtLogin.toggle() }

    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: Helpers

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: key)
        mi.target = self
        return mi
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        mi.isEnabled = false
        return mi
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
