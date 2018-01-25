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

    func testMixedHTMLContentParsing() {
        let referenceHTML = "<code>Inline code</code> and some other text"
        let attributedString = Ashton.decode(referenceHTML, containsMixedContent: true)
        XCTAssertEqual(attributedString.string, "Inline code and some other text")

        let referenceHTML2 = "<p style='font: 16px \"Helvetica\"; text-decoration: line-through; -cocoa-font-postscriptname: \"Helvetica\";'><strong>Sub<u>topic</u></strong> 2</p>"
        let attributedString2 = Ashton.decode(referenceHTML2, containsMixedContent: true)
        XCTAssertEqual(attributedString2.string, "Subtopic 2")
    }

	func testRTFTestFileRoundTrip() {
        let attributedString = self.loadAttributedString(fromRTF: "RTFText")

        let oldAshtonHTML = attributedString.mn_HTMLRepresentation()!
        let oldAshtonAttributedString = NSAttributedString(htmlString: oldAshtonHTML)!

        let html = Ashton.encode(oldAshtonAttributedString)
        // we compare with benchmark only on macOS as iOS Ashton old drops attributes here
        #if os(macOS)
        XCTAssertEqual(oldAshtonHTML, html)
        #endif
        let decodedString = Ashton.decode(html)
        let roundTripHTML = Ashton.encode(decodedString)
        let roundTripDecodedString = Ashton.decode(roundTripHTML)
        XCTAssertEqual(roundTripHTML, html)
        XCTAssertEqual(roundTripDecodedString, decodedString)
	}

	func testAttributeCodingWithBenchmark() {
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
        let urlString = URL(string: "https://www.orf.at")!
		self.compareAttributeCodingWithBenchmark(.link, values: [urlString], ignoreReferenceHTML: false)
	}

    func testHTMLEscapingInHref() {
        let attributedString = NSMutableAttributedString(string: "Test: Link to test. That's it")
        let url = URL(string: "http://google.com?a='b'&c='test'")!
        attributedString.addAttribute(.link, value: url, range: NSRange(location: 6, length: 13))
        let html = Ashton.encode(attributedString)
        let roundtripped = Ashton.decode(html)
        XCTAssertEqual(attributedString, roundtripped)
    }

    func testHTMLEscapingInHrefParagraph() {
        let url = URL(string: "http://google.com?a='b'&c='test'")!
        let attributedString = NSMutableAttributedString(string: "Test: Link to test. That's it", attributes: [.link: url])
        let html = Ashton.encode(attributedString)
        let roundtripped = Ashton.decode(html)
        XCTAssertEqual(attributedString, roundtripped)
    }

    func testCombiningOfParagraphsAttributes() {
        let asthonHTML = "<p style='color: rgba(52, 72, 83, 1.000000); font: 18px \"Palatino\"; -cocoa-font-postscriptname: \"Palatino-Roman\"; '>Line1</p><p style='color: rgba(52, 72, 83, 1.000000); font: 18px \"Palatino\"; -cocoa-font-postscriptname: \"Palatino-Roman\"; '>Line2</p>"
        let attributedString = Ashton.decode(asthonHTML)
        let range = NSMakeRange(0, attributedString.length)
        var maxRange: NSRange = NSRange()
        attributedString.attributes(at: 0, longestEffectiveRange: &maxRange, in: range)
        XCTAssertEqual(range, maxRange)
    }

    func testReadStringWithMissingFontFamilyName() {
        let ashtonHTML = "<p style='text-align: left; '><span style='color: rgba(52, 72, 83, 1.000000); font: 18px \"\"; -cocoa-font-postscriptname: \"Arial\"; '>\\UF016</span><span style='color: rgba(52, 72, 83, 1.000000); font: 18px \"Helvetica Neue\"; -cocoa-font-postscriptname: \"HelveticaNeue\"; '>  1. Numbers</span></p>"
        let attributedString = Ashton.decode(ashtonHTML)
        let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
        let font = attributes[.font] as! Font
        XCTAssertEqual(font.cpFamilyName, "Arial")
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
            let attributedString = NSMutableAttributedString(string: "Has changed alignment\nNext line with no attribute\nThis is normal text")
            attributedString.addAttribute(.paragraphStyle,
                                          value: paragraphStyle,
                                          range: NSRange(location: 0, length: 22))
            let html = Ashton.encode(attributedString)
            let convertedBack = Ashton.decode(html)
            XCTAssertEqual(attributedString, convertedBack)
        }
    }

	func testFonts() {
        let font1 = Font(name: "Arial", size: 12)!
        let font2 = Font(name: "Helvetica-Bold", size: 16)!
        let sampleString = NSMutableAttributedString(string: "Hello World")
        sampleString.addAttribute(.font, value: font1, range: NSRange(location: 0, length: 5))
        sampleString.addAttribute(.font, value: font2, range: NSRange(location: 6, length: 5))

        let html = Ashton.encode(sampleString)
        let roundTrippedString = Ashton.decode(html)
        let roundTrippedHTML = Ashton.encode(roundTrippedString)

        XCTAssertEqual(html, roundTrippedHTML)
        // we compare the rountripped attributed string only on iOS as the comparison of the bridged NSFont (from CTFont)
        // with the original NSFont leads to wrong failure
        #if os(iOS)
            XCTAssertEqual(sampleString, roundTrippedString)
        #endif
	}

    func testSavingAndLoadingOfStringsWithControlCharacters() {
        let stringWithControlChars = "Hello\u{1} World"
        let attributedString = NSAttributedString(string: stringWithControlChars)

        let html = Ashton.encode(attributedString)
        let decodedString = Ashton.decode(html)
        XCTAssertEqual(stringWithControlChars, decodedString.string)
    }

    func testFontFeatures() {
        let ashtonHTML = "<p style= '-cocoa-font-features: 3/3; font: 14px \"Hoefler Text\"; text-align: left; color: rgba(0, 0, 0, 1.000000); '>hello world</p>"
        let attributedString = Ashton.decode(ashtonHTML)
        let referenceAttributedString = NSAttributedString(htmlString: ashtonHTML)
        let referenceHTML = referenceAttributedString?.mn_HTMLRepresentation()
        let roundtrippedHTML = Ashton.encode(attributedString)
        XCTAssertEqual(referenceHTML, roundtrippedHTML)
    }

    func testCacheClearing() {
        let ashtonHTML = "<p style= '-cocoa-font-features: 3/3; font: 14px \"Hoefler Text\"; text-align: left; color: rgba(0, 0, 0, 1.000000); '>hello world</p>"
        _ = Ashton.decode(ashtonHTML)

        XCTAssertFalse(FontBuilder.fontCache.isEmpty)
        XCTAssertFalse(AshtonXMLParser.styleAttributesCache.isEmpty)
        Ashton.clearCaches()
        XCTAssertTrue(FontBuilder.fontCache.isEmpty)
        XCTAssertTrue(AshtonXMLParser.styleAttributesCache.isEmpty)
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

    func testSampleRTFTextDecodingPerformance() {
        let attributedString = self.loadAttributedString(fromRTF: "RTFText")
        let html = Ashton.encode(attributedString) + ""
        self.measure {
//                        let test1 = NSAttributedString(htmlString: html) // old ashton benchmark
//                        let test2 = NSAttributedString(htmlString: html) // old ashton benchmark
            let test1 = Ashton.decode(html)
            let test2 = Ashton.decode(html)
            XCTAssertEqual(test1, test2)
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
