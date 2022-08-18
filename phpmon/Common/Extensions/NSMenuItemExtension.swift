//
//  NSMenuItem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/08/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension NSMenuItem {
    convenience init(
        title: String,
        action: Selector? = nil,
        keyEquivalent: String = "",
        keyModifier: NSEvent.ModifierFlags = [],
        toolTip: String? = nil
    ) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)
        self.keyEquivalentModifierMask = keyModifier
        self.toolTip = toolTip
    }
}

// MARK: - NSMenuItem subclasses

class PhpMenuItem: NSMenuItem {
    var version: String = ""
}

class XdebugMenuItem: NSMenuItem {
    var mode: String = ""
}

class ExtensionMenuItem: NSMenuItem {
    var phpExtension: PhpExtension?
}

class EditorMenuItem: NSMenuItem {
    var editor: Application?
}

class PresetMenuItem: NSMenuItem {
    var preset: Preset?

    static func getAll() -> [NSMenuItem] {
        return Preferences.custom.presets!.map { preset in
            let presetMenuItem = PresetMenuItem(
                title: preset.getMenuItemText(),
                action: #selector(MainMenu.togglePreset(sender:))
            )

            if let attributedString = try? NSMutableAttributedString(
                data: preset.getMenuItemText().data(using: .utf8)!,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            ) {
                presetMenuItem.attributedTitle = attributedString
            }

            presetMenuItem.preset = preset
            return presetMenuItem
        }
    }
}
