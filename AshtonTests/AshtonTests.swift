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

	func testAttributeEncodingWithBenchmark() {
		let testColors = [UIColor.red, UIColor(hue: 0.2, saturation: 0.1, brightness: 0.3, alpha: 0.7)]
		self.compareAttributeEncodingWithBenchmark(.backgroundColor, values: testColors)
		self.compareAttributeEncodingWithBenchmark(.foregroundColor, values: testColors)
		self.compareAttributeEncodingWithBenchmark(.strikethroughColor, values: testColors)
		self.compareAttributeEncodingWithBenchmark(.underlineColor, values: testColors)
		let underlineStyles: [NSUnderlineStyle] = [.styleSingle]//, .styleThick, .styleDouble]
		self.compareAttributeEncodingWithBenchmark(.underlineStyle, values: underlineStyles.map { $0.rawValue })
		self.compareAttributeEncodingWithBenchmark(.strikethroughStyle, values: underlineStyles.map { $0.rawValue })
	}

	func testParagraphSpacing() {
		let attributedString = NSMutableAttributedString(string: "Hello World.\nThis is line 2.\nThisIsLine3\n\nThis is line 4")
		let referenceHtml = attributedString.mn_HTMLRepresentation()!
		let html = Ashton.encode(attributedString)
		XCTAssertEqual(html, referenceHtml)

		let convertedBack = NSAttributedString(htmlString: referenceHtml)!
		XCTAssertEqual(convertedBack, attributedString)
	}

	func testParagraphSpacingPerformance() {
		let attributedString = NSMutableAttributedString(string: "Hello World.\nThis is line 2.\nThisIsLine3\n\nThis is line 4")

		self.measure {
			for _ in 0...10000 {
				//let html = attributedString.mn_HTMLRepresentation()!
				let html = Ashton.encode(attributedString)
			}
		}
	}
}

// MARK: - Private

private extension AshtonTests {

	func compareAttributeEncodingWithBenchmark(_ attribute: NSAttributedStringKey, values: [Any]) {
		for value in values {
			let attributedString = NSMutableAttributedString(string: "Test: Any attribute with Benchmark.\nNext line with no attribute")
			attributedString.addAttribute(attribute,
			                              value: value,
			                              range: NSRange(location: 6, length: 10))
			let referenceHtml = attributedString.mn_HTMLRepresentation()!
			let html = Ashton.encode(attributedString)
			XCTAssertEqual(referenceHtml, html)
		}
	}
}
