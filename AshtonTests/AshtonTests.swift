//
//  AshtonTests.swift
//  AshtonTests
//
//  Created by Michael Schwarz on 16.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import XCTest
@testable import Ashton

class AshtonTests: XCTestCase {

    func testExample() {
		let htmlWriter = AshtonHTMLWriter()
		XCTAssertNotNil(htmlWriter)
    }
}
