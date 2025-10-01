//
//  SettingsView.swift
//  DartTimer
//
//  Created by Steinhauer, Jan on 01.10.25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [DTSettings]
    @State private var local: DTSettings = DTSettings()

    var body: some View {
        Form {
            Toggle("Sound", isOn: $local.soundOn)
            Toggle("Haptics", isOn: $local.hapticsOn)
            ColorPicker("Theme", selection: Binding(
                get: { Color(hex: local.themeHex) ?? .habitOrange },
                set: { local.themeHex = $0.toHex ?? "#FF9F0A" }
            ))
            Button("Save") {
                if let s = settings.first {
                    s.soundOn = local.soundOn
                    s.hapticsOn = local.hapticsOn
                    s.themeHex = local.themeHex
                } else {
                    modelContext.insert(local)
                }
                try? modelContext.save()
            }
        }
        .onAppear {
            if let s = settings.first { local = s }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Small Color ↔ Hex helpers

fileprivate extension Color {
    init?(hex: String) {
        guard let c = Color(hex) else { return nil }
        self = c
    }
    static func fromHex(_ hex: String) -> Color? { Color(hex) }
    init?(_ hex: String) {
        guard let c = Color(hex) else { return nil }
        self = c
    }
}

fileprivate extension Color {
    /// Minimal hex encode/decode for opaque colors.
    var toHex: String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let R = Int(round(r*255)), G = Int(round(g*255)), B = Int(round(b*255))
        return String(format:"#%02X%02X%02X", R,G,B)
    }
}


