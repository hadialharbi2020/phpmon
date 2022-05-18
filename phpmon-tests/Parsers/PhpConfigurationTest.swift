//
//  PhpIniTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class PhpConfigurationTest: XCTestCase {

    static var phpIniFileUrl: URL {
        return Bundle(for: Self.self).url(forResource: "php", withExtension: "ini")!
    }

    func testCanLoadExtension() throws {
        let iniFile = PhpConfigurationFile.from(filePath: Self.phpIniFileUrl.path)!

        XCTAssertNotNil(iniFile)

        XCTAssertGreaterThan(iniFile.extensions.count, 0)
    }

    func testCanSwapConfigurationValue() throws {
        let destination = Utility.copyToTemporaryFile(resourceName: "php", fileExtension: "ini")!

        let configurationFile = PhpConfigurationFile.from(filePath: destination.path)

        XCTAssertNotNil(configurationFile)
    }

}
