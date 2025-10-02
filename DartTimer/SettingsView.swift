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
                get: { Color(hexString: local.themeHex) ?? .habitOrange },
                set: { newColor in local.themeHex = newColor.toHex() ?? "#FF9F0A" }
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

extension Color {
    /// Create a Color from hex like "#FF9F0A", "FF9F0A", "#AARRGGBB", "AARRGGBB".
    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }

        // Support RGB (6) or ARGB/RGBA (8)
        let scanner = Scanner(string: s)
        var hex: UInt64 = 0
        guard scanner.scanHexInt64(&hex) else { return nil }

        switch s.count {
        case 6: // RRGGBB
            let r = Double((hex & 0xFF0000) >> 16) / 255.0
            let g = Double((hex & 0x00FF00) >> 8)  / 255.0
            let b = Double(hex & 0x0000FF)         / 255.0
            self = Color(red: r, green: g, blue: b)
        case 8: // AARRGGBB or RRGGBBAA — assume AARRGGBB (common for design tokens)
            let a = Double((hex & 0xFF000000) >> 24) / 255.0
            let r = Double((hex & 0x00FF0000) >> 16) / 255.0
            let g = Double((hex & 0x0000FF00) >> 8)  / 255.0
            let b = Double(hex & 0x000000FF)         / 255.0
            self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
        default:
            return nil
        }
    }

    /// Convert to "#RRGGBB" (ignores alpha).
    func toHex(includeAlpha: Bool = false) -> String? {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let R = Int(round(r * 255)), G = Int(round(g * 255)), B = Int(round(b * 255))
        if includeAlpha {
            let A = Int(round(a * 255))
            return String(format: "#%02X%02X%02X%02X", A, R, G, B)
        } else {
            return String(format: "#%02X%02X%02X", R, G, B)
        }
        #else
        return nil
        #endif
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


