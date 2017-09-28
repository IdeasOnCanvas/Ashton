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

	func testAttributeCodingWithBenchmark() {
		let testColors = [UIColor.red, UIColor.green]
		self.compareAttributeCodingWithBenchmark(.backgroundColor, values: testColors)
		self.compareAttributeCodingWithBenchmark(.foregroundColor, values: testColors)
		self.compareAttributeCodingWithBenchmark(.strikethroughColor, values: testColors)
		self.compareAttributeCodingWithBenchmark(.underlineColor, values: testColors)
		let underlineStyles: [NSUnderlineStyle] = [.styleSingle]//, .styleThick, .styleDouble]
		self.compareAttributeCodingWithBenchmark(.underlineStyle, values: underlineStyles.map { $0.rawValue })
		self.compareAttributeCodingWithBenchmark(.strikethroughStyle, values: underlineStyles.map { $0.rawValue })
	}

	func testParagraphSpacing() {
		let attributedString = NSMutableAttributedString(string: "\n Hello World.\nThis is line 2. \nThisIsLine3\n\nThis is line 4")
		let html = Ashton.encode(attributedString)
		let convertedBack = Ashton.decode(html)
		XCTAssertEqual(attributedString, convertedBack)
	}

	func testURLs() {
		let url = URL(string: "https://www.orf.at")!

		self.compareAttributeCodingWithBenchmark(.link, values: [url], ignoreReferenceHTML: false)
	}

	func testFonts() {
		let font1 = UIFont.systemFont(ofSize: 12)
		let font2 = UIFont.boldSystemFont(ofSize: 14)
		// we ignore the old Ashton reference HTML as we encode more attributes
		self.compareAttributeCodingWithBenchmark(.font, values: [font1, font2], ignoreReferenceHTML: true)
	}

	// MARK: - Performance Tests

	func testParagraphDecodingPerformance() {
		let attributedString = NSMutableAttributedString(string: " Hello World. \nThis is line 2.\nThisIsLine3\n\nThis is line 4")
		let html = Ashton.encode(attributedString)

		self.measure {
			for _ in 0...1000 {
				_ = Ashton.decode(html)
			}
		}
	}

	func testParagraphEncodingPerformance() {
		let attributedString = NSMutableAttributedString(string: " Hello World. \nThis is line 2.\nThisIsLine3\n\nThis is line 4")

		self.measure {
			for _ in 0...1000 {
				_ = Ashton.encode(attributedString)
			}
		}
	}

	func testAttributeDecodingPerformance() {
		let attributedString = NSMutableAttributedString(string: "Test: Any attribute with Benchmark.\n\nNext line with no attribute")
		attributedString.addAttribute(.backgroundColor,
		                              value: UIColor.green,
		                              range: NSRange(location: 6, length: 10))

		let referenceHtml = attributedString.mn_HTMLRepresentation()!

		self.measure {
			for _ in 0...1000 {
				_ = Ashton.decode(referenceHtml)
			}
		}
	}
}

// MARK: - Private

private extension AshtonTests {

	func compareAttributeCodingWithBenchmark(_ attribute: NSAttributedStringKey, values: [Any], ignoreReferenceHTML: Bool = false) {
		for value in values {
			let attributedString = NSMutableAttributedString(string: "Test: Any attribute with Benchmark.\n\nNext line with no attribute")
			attributedString.addAttribute(attribute,
			                              value: value,
			                              range: NSRange(location: 6, length: 10))
			let referenceHtml = attributedString.mn_HTMLRepresentation()!
			let html = Ashton.encode(attributedString)
			if ignoreReferenceHTML == false {
				XCTAssertEqual(referenceHtml, html)
			}

			let decodedString = Ashton.decode(html)
			XCTAssertEqual(decodedString, attributedString)
		}
	}
}
