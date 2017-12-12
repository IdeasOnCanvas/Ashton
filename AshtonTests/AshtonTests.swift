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

	func testRTFTestFileRoundTrip() {
		let rtfURL = Bundle(for: AshtonTests.self).url(forResource: "Test1", withExtension: "rtf")!
		let attributedString = try? NSAttributedString(url: rtfURL, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
		XCTAssertNotNil(attributedString)

		let html = Ashton.encode(attributedString!)
		let referenceHTML = attributedString!.mn_HTMLRepresentation()
		print(html)

		XCTAssertEqual(html, referenceHTML)

		print(attributedString!)
	}

	func testAttributeCodingWithBenchmark() {
        // we ignore the reference HTML here because Asthon old looses rgb precision when converting
		let testColors = [Color.red, Color.green]
		self.compareAttributeCodingWithBenchmark(.backgroundColor, values: testColors, ignoreReferenceHTML: true)
		self.compareAttributeCodingWithBenchmark(.foregroundColor, values: testColors, ignoreReferenceHTML: true)
		self.compareAttributeCodingWithBenchmark(.strikethroughColor, values: testColors, ignoreReferenceHTML: true)
		self.compareAttributeCodingWithBenchmark(.underlineColor, values: testColors, ignoreReferenceHTML: true)
		let underlineStyles: [NSUnderlineStyle] = [.styleSingle]//, .styleThick, .styleDouble]
		self.compareAttributeCodingWithBenchmark(.underlineStyle, values: underlineStyles.map { $0.rawValue }, ignoreReferenceHTML: true)
		self.compareAttributeCodingWithBenchmark(.strikethroughStyle, values: underlineStyles.map { $0.rawValue }, ignoreReferenceHTML: true)
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
        let font1 = Font(name: "Arial", size: 12)!
        let font2 = Font(name: "Helvetica-Bold", size: 14)!
		self.compareAttributeCodingWithBenchmark(.font, values: [font1, font2], ignoreReferenceHTML: false)
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
		                              value: Color.green,
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
