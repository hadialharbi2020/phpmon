//
//  Shell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

var Shell: Shellable {
    return ActiveShell.shared
}

class ActiveShell {
    static var shared: Shellable = SystemShell()

    public static func useTestable(_ expectations: [String: BatchFakeShellOutput]) {
        Self.shared = TestableShell(expectations: expectations)
    }

    public static func useSystem() {
        Self.shared = SystemShell()
    }
}
