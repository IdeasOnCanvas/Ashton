//
//  AshtonBechmarkTests.swift
//  AshtonBenchmarkTests
//
//  Created by Michael Schwarz on 12.11.20.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import XCTest
@testable import Ashton


/// Tests for comparing Ashton 2.0 with the 1.0 (objc) reference implementation
/// Because of Objc dependency and resource handling those tests are excluded from SPM and only executed via project
class AshtonBenchmarkTests: XCTestCase {

    func testTextStyles() {
        let attributedString = self.loadAttributedString(fromRTF: "TextStyles")
        let html = Ashton.encode(attributedString)
        let roundTripAttributedString = Ashton.decode(html)
        let roundTripHTML = Ashton.encode(roundTripAttributedString)
        XCTAssertEqual(html, roundTripHTML)
    }

    func testRTFTestFileRoundTrip() {
        let attributedString = self.loadAttributedString(fromRTF: "RTFText")

        let html = Ashton.encode(attributedString)
        let decodedString = Ashton.decode(html)
        let roundTripHTML = Ashton.encode(decodedString)
        let roundTripDecodedString = Ashton.decode(roundTripHTML)
        XCTAssertEqual(roundTripHTML, html)
        XCTAssertEqual(roundTripDecodedString, decodedString)
    }

    func testVerticalAlignment() {
        let key = NSAttributedString.Key(rawValue: "NSSuperScript")
        self.compareAttributeCodingWithBenchmark(key, values: [2, -2], ignoreReferenceHTML: true)
    }

    func testURLs() {
        let urlString = URL(string: "https://www.orf.at")!
        self.compareAttributeCodingWithBenchmark(.link, values: [urlString], ignoreReferenceHTML: false)
    }

    func testAttributeCodingWithBenchmark() {
        let testColors = [Color.red, Color.green]
        self.compareAttributeCodingWithBenchmark(.backgroundColor, values: testColors, ignoreReferenceHTML: true)
        self.compareAttributeCodingWithBenchmark(.foregroundColor, values: testColors, ignoreReferenceHTML: true)
        self.compareAttributeCodingWithBenchmark(.strikethroughColor, values: testColors, ignoreReferenceHTML: true)
        self.compareAttributeCodingWithBenchmark(.underlineColor, values: testColors, ignoreReferenceHTML: true)
        let underlineStyles: [NSUnderlineStyle] = [NSUnderlineStyle.single]//, .styleThick, .styleDouble]
        self.compareAttributeCodingWithBenchmark(.underlineStyle, values: underlineStyles.map { $0.rawValue }, ignoreReferenceHTML: true)
        self.compareAttributeCodingWithBenchmark(.strikethroughStyle, values: underlineStyles.map { $0.rawValue }, ignoreReferenceHTML: true)
    }

    func testArabicCharacterParsing() {
        let html = "<p style=\'color: rgba(75, 75, 75, 1.000000); font: 24px \"Geeza Pro\"; text-align: center; -cocoa-font-postscriptname: \"GeezaPro\"; \'>لالالالالالالالالا</p>"
        let attributedString = Ashton.decode(html)
        let reference = NSAttributedString(htmlString: html)!
        let canvasSize = CGSize(width: 200.0, height: 200.0)
        let drawingRect = attributedString.boundingRect(with: canvasSize, options: [.usesDeviceMetrics], context: nil)
        let referenceRect = reference.boundingRect(with: canvasSize, options: [.usesDeviceMetrics], context: nil)
        XCTAssertEqual(drawingRect, referenceRect)
        XCTAssertEqual(attributedString.string, reference.string)
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

    func testSampleRTFTextDecodingPerformance() {
        let attributedString = self.loadAttributedString(fromRTF: "RTFText")
        let html = Ashton.encode(attributedString) + ""
        self.measure {
//                        let test1 = NSAttributedString(htmlString: html) // old ashton benchmark
  //                     let test2 = NSAttributedString(htmlString: html) // old ashton benchmark
            let test1 = Ashton.decode(html)
            let test2 = Ashton.decode(html)
            XCTAssertEqual(test1, test2)
        }
    }

    func testSampleRTFTextEncodingPerformance() {
        let attributedString = self.loadAttributedString(fromRTF: "RTFText")
        self.measure {
            //let test1 = attributedString.mn_HTMLRepresentation()! // old ashton benchmark
            //let test2 = attributedString.mn_HTMLRepresentation()! // old ashton benchmark
            let test1 = Ashton.encode(attributedString)
            let test2 = Ashton.encode(attributedString)
            XCTAssertEqual(test1, test2)
        }
    }
}

// MARK: - Private

private extension AshtonBenchmarkTests {

    func loadAttributedString(fromRTF fileName: String) -> NSAttributedString {
        let rtfURL = Bundle(for: AshtonTests.self).url(forResource: fileName, withExtension: "rtf")!
        return try! NSAttributedString(url: rtfURL, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
    }

    func compareAttributeCodingWithBenchmark(_ attribute: NSAttributedString.Key, values: [Any], ignoreReferenceHTML: Bool = false) {
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
