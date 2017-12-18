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

    func testTextStyles() {
        let attributedString = self.loadAttributedString(fromRTF: "TextStyles")
        let html = Ashton.encode(attributedString)
        let benchmarkHTML = attributedString.mn_HTMLRepresentation()!
        // we compare with benchmark only on macOS as iOS Ashton old drops attributes here
        #if os(macOS)
        XCTAssertEqual(html, benchmarkHTML)
        #endif
        let roundTripAttributedString = Ashton.decode(html)
        let roundTripHTML = Ashton.encode(roundTripAttributedString)
        XCTAssertEqual(html, roundTripHTML)
    }

    func testStyleTagsOrdering() {
        let referenceHTML = "<p style='font: 16px \"Helvetica\"; text-decoration: line-through; -cocoa-font-postscriptname: \"Helvetica\"; -cocoa-strikethrough: single; -cocoa-strikethrough-color: rgba(0, 0, 0, 1.000000); -cocoa-underline-color: rgba(255, 0, 0, 1.000000); '>Single Strikethrough.</p>"
        let roundTripHTML = Ashton.encode(Ashton.decode(referenceHTML))
        XCTAssertEqual(referenceHTML, roundTripHTML)
    }

	func testRTFTestFileRoundTrip() {
        let attributedString = self.loadAttributedString(fromRTF: "RTFText")

        let oldAshtonHTML = attributedString.mn_HTMLRepresentation()!
        let oldAshtonAttributedString = NSAttributedString(htmlString: oldAshtonHTML)!

        let html = Ashton.encode(oldAshtonAttributedString)
        XCTAssertEqual(oldAshtonHTML, html)
        let decodedString = Ashton.decode(html)
        let roundTripHTML = Ashton.encode(decodedString)
        let roundTripDecodedString = Ashton.decode(roundTripHTML)

        print("\n\n\nRT\n\(roundTripHTML)\n\n\\IN\n\(html)\n\n")

     //   XCTAssertEqual(roundTripHTML, html)
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

    func testVerticalAlignment() {
        let key = NSAttributedStringKey(rawValue: "NSSuperScript")
        self.compareAttributeCodingWithBenchmark(key, values: [2, -2], ignoreReferenceHTML: true)
    }

    func testTextAlignment() {
        let alignments: [NSTextAlignment] = [.center, .left, .right, .justified]
        let paragraphStyles: [NSParagraphStyle] = alignments.map { alignment in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment
            return paragraphStyle
        }
        for paragraphStyle in paragraphStyles {
            let attributedString = NSMutableAttributedString(string: "This is a text with changed alignment\n\nNext line with no attribute\nThis is normal text")
            attributedString.addAttribute(.paragraphStyle,
                                          value: paragraphStyle,
                                          range: NSRange(location: 0, length: 37))
            let html = Ashton.encode(attributedString)
            let convertedBack = Ashton.decode(html)
            XCTAssertEqual(attributedString, convertedBack)
        }
    }

	func testFonts() {
        let font1 = Font(name: "Arial", size: 12)!
        let font2 = Font(name: "Helvetica-Bold", size: 16)!
		self.compareAttributeCodingWithBenchmark(.font, values: [font1, font2], ignoreReferenceHTML: false)
	}

	// MARK: - Performance Tests

	func testParagraphDecodingPerformance() {
		let attributedString = NSMutableAttributedString(string: " Hello World. \nThis is line 2.\nThisIsLine3\n\nThis is line 4")
		let html = Ashton.encode(attributedString)

		self.measure {
			for _ in 0...1000 {
                //_ = NSAttributedString(htmlString: html) // old ashton benchmark
				_ = Ashton.decode(html)
			}
		}
	}

	func testParagraphEncodingPerformance() {
		let attributedString = NSMutableAttributedString(string: " Hello World. \nThis is line 2.\nThisIsLine3\n\nThis is line 4")

		self.measure {
			for _ in 0...1000 {
                //_ = attributedString.mn_HTMLRepresentation()! // old ashton benchmark
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
                //_ = NSAttributedString(htmlString: referenceHtml) // old ashton benchmark
				_ = Ashton.decode(referenceHtml)
			}
		}
	}
}

// MARK: - Private

private extension AshtonTests {

    func loadAttributedString(fromRTF fileName: String) -> NSAttributedString {
        let rtfURL = Bundle(for: AshtonTests.self).url(forResource: fileName, withExtension: "rtf")!
        return try! NSAttributedString(url: rtfURL, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
    }

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
