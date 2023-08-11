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

    func testEncodingOfMultipleTextDecorationStyles() {
        let attributedString = NSAttributedString(string: "Hello World", attributes: [.underlineStyle: NSUnderlineStyle.double.rawValue,
                                                                                      .strikethroughStyle: NSUnderlineStyle.double.rawValue])
        let html = Ashton.encode(attributedString)
        let expectedHTML = "<p style='text-decoration: line-through underline; -cocoa-strikethrough: double; -cocoa-underline: double; '>Hello World</p>"
        XCTAssertEqual(html, expectedHTML)
    }

    func testDecodingOfMultipleDecorationStyles() {
        let html = "<p style='text-decoration: line-through underline; '>Hello World</p>"
        let roundTrippedHTML = Ashton.encode(Ashton.decode(html))
        XCTAssertTrue(roundTrippedHTML.contains("text-decoration: line-through underline"))
    }

    func testDecodingOfStrongTag() {
        let html = "Hello <strong>World</strong>"
        let attributedString = Ashton.decode(html, defaultAttributes: [.font: Font(name: "Helvetica", size: 12.0)!])
        let roundTripHTML = Ashton.encode(attributedString)

        XCTAssertEqual(roundTripHTML, "<p><span style='font: 12px \"Helvetica\"; -cocoa-font-postscriptname: \"Helvetica\"; '>Hello </span><span style='font: bold 12px \"Helvetica\"; -cocoa-font-postscriptname: \"Helvetica-Bold\"; '>World</span></p>")
    }

    func testDecodingOfEmTag() {
        let html = "Hello <em>World</em>"
        let attributedString = Ashton.decode(html, defaultAttributes: [.font: Font(name: "Helvetica", size: 12.0)!])
        let roundTripHTML = Ashton.encode(attributedString)

        XCTAssertEqual(roundTripHTML, "<p><span style='font: 12px \"Helvetica\"; -cocoa-font-postscriptname: \"Helvetica\"; '>Hello </span><span style='font: italic 12px \"Helvetica\"; -cocoa-font-postscriptname: \"Helvetica-Oblique\"; '>World</span></p>")
    }

    func testRoundTripWithNewlines() {
        let string = "\n\nHello World,\n\n\nwith trailing whitespace\n\n\n"
        let attributedString = NSAttributedString(string: string)
        let html = Ashton.encode(attributedString)

        let roundTripAttributedString = Ashton.decode(html)
        XCTAssertEqual(attributedString, roundTripAttributedString)
    }

    func testPersistenceOfMultipleNewlines() {
        let string = "\n\n\n\n\n"
        let attributedString = NSAttributedString(string: string)
        let html = Ashton.encode(attributedString)

        let roundTripAttributedString = Ashton.decode(html)
        XCTAssertEqual(attributedString, roundTripAttributedString)
    }

    func testRoundtrippingEmptyString() {
        let string = ""
        let attributedString = NSAttributedString(string: string)
        let html = Ashton.encode(attributedString)

        let roundTripAttributedString = Ashton.decode(html)
        XCTAssertEqual(attributedString, roundTripAttributedString)
    }

    func testNewlineAfterParagraph() {
        let html = "<p style=\'color: rgba(0, 0, 0, 1.000000); font: 24px \"Avenir Next\"; text-align: center; -cocoa-font-postscriptname: \"AvenirNext-Medium\"; \'>Line1</p><p style=\'color: rgba(0, 0, 0, 1.000000); font: 24px \"Avenir Next\"; text-align: center; -cocoa-font-postscriptname: \"AvenirNext-Medium\"; \'>Line2</p><p style=\'color: rgba(0, 0, 0, 1.000000); font: 24px \"Avenir Next\"; text-align: center; -cocoa-font-postscriptname: \"AvenirNext-Medium\"; \'>Line3</p>"
        let attributedString = Ashton.decode(html)
        XCTAssertEqual(attributedString.string, "Line1\nLine2\nLine3")
    }

    func testStyleTagsOrdering() {
        let referenceHTML = "<p style='font: 16px \"Helvetica\"; text-decoration: line-through; -cocoa-font-postscriptname: \"Helvetica\"; -cocoa-strikethrough: single; -cocoa-strikethrough-color: rgba(0, 0, 0, 1.000000); -cocoa-underline-color: rgba(255, 0, 0, 1.000000); '>Single Strikethrough.</p>"
        let roundTripHTML = Ashton.encode(Ashton.decode(referenceHTML))
        XCTAssertEqual(referenceHTML, roundTripHTML)
    }

    func testParsingOfContentWithMalformedHTML() {
        let referenceHTML = "</code>Inline <span>code</span></code> and some other text"
        let resultingString = Ashton.decode(referenceHTML).string
        XCTAssertEqual(resultingString, "Inline code and some other text")
    }

    func testMixedHTMLContentParsing() {
        let referenceHTML = "<code>Inline code</code> and some other text"
        let attributedString = Ashton.decode(referenceHTML)
        XCTAssertEqual(attributedString.string, "Inline code and some other text")

        let referenceHTML2 = "<p style='font: 16px \"Helvetica\"; text-decoration: line-through; -cocoa-font-postscriptname: \"Helvetica\";'><strong>Sub<u>topic</u></strong> 2</p>"
        let attributedString2 = Ashton.decode(referenceHTML2)
        XCTAssertEqual(attributedString2.string, "Subtopic 2")
    }

    func testDecodingOfPostScriptFont() {
        let referenceHTML = "<p style=\'color: rgba(12, 25, 7, 1.000000); font: bold 18px \"Helvetica Neue\"; text-align: center; text-decoration: underline; -cocoa-font-postscriptname: \"HelveticaNeue-Bold\"; -cocoa-underline: single; \'>Marketing</p>"
        let attributedString = Ashton.decode(referenceHTML, completionHandler: { result in
            XCTAssertTrue(result.unknownFonts.isEmpty)
        })
        let roundTripped = Ashton.encode(attributedString)
        XCTAssertEqual(referenceHTML, roundTripped)
    }

	func testParagraphSpacing() {
        let attributedString = NSMutableAttributedString(string: "\n Hello World.\nThis is line 2. \nThisIsLine3\n\nThis is line 4")
        let html = Ashton.encode(attributedString)
        let convertedBack = Ashton.decode(html)
        XCTAssertEqual(attributedString, convertedBack)
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

    func testKnownFontParsing() {
        let familyNames = Font.cpFamilyNames
        for familyName in familyNames {
            for fontName in Font.cpFontNames(forFamilyName: familyName) {
                let sampleHTML = "<p style='color: rgba(72, 72, 72, 1.000000); font: 18px \"\(fontName)\"; text-align: left; '>Hello World</p>"
                _ = Ashton.decode(sampleHTML) { result in
                    XCTAssert(result.unknownFonts.count == 0)
                }
            }
        }
    }

    func testUnknownFontParsing() {
        let sampleHTML = "<p style='color: rgba(72, 72, 72, 1.000000); font: 18px \"Suisse Int'l\"; text-align: left; -cocoa-font-postscriptname: \"SuisseIntl-Regular\"; '>Hello World</p>"
        var unknownFont: String?
        _ = Ashton.decode(sampleHTML) { result in
            XCTAssert(result.unknownFonts.count == 1)
            unknownFont = result.unknownFonts.first
        }
        XCTAssertEqual(unknownFont, "SuisseIntl-Regular")
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
        #if os(iOS) || os(visionOS)
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
        let sampleHTML = ["<p style='color: rgba(0, 0, 0, 1.000000); font: 14px \"Hoefler Text\"; text-align: left; -cocoa-font-features: 3/3; -cocoa-font-postscriptname: \"HoeflerText-Regular\"; '>hello world</p>",
                          "<p style='color: rgba(91, 91, 91, 1.000000); font: 18px \"Avenir Next\"; text-align: center; -cocoa-font-features: 37/1 38/1; -cocoa-font-postscriptname: \"AvenirNext-Regular\"; '>Also helps the bike to stay clean longer!</p>"]
        sampleHTML.forEach { ashtonHTML in
            let attributedString = Ashton.decode(ashtonHTML)
            let roundtrippedHTML = Ashton.encode(attributedString)
            XCTAssertEqual(ashtonHTML, roundtrippedHTML)
        }
    }

    func testCacheClearing() {
        let ashtonHTML = "<p style= '-cocoa-font-features: 3/3; font: 14px \"Hoefler Text\"; text-align: left; color: rgba(0, 0, 0, 1.000000); '>hello world</p>"
        _ = Ashton.decode(ashtonHTML)

        XCTAssertFalse(Ashton.reader.fontBuilderCache.isEmpty)
        XCTAssertFalse(Ashton.reader.xmlParser.styleAttributesCache.isEmpty)
        Ashton.clearCaches()
        XCTAssertTrue(Ashton.reader.fontBuilderCache.isEmpty)
        XCTAssertTrue(Ashton.reader.xmlParser.styleAttributesCache.isEmpty)
    }

    func testReadingOfUnknownTags() {
        let ashtonHTML = "<bla hreference='' hoax='' stuff='bla' unknownAttributeName= '-cocoa-font-features: 3/3; font: 14px \"Hoefler Text\"; text-align: left; color: rgba(0, 0, 0, 1.000000); '>hello world</bla>"
        let attributedString = Ashton.decode(ashtonHTML)
        XCTAssertEqual(attributedString.string, "hello world")

        let ashtonHTML2 = "<span hreference='' hoax='' stuff='bla' style= '-cocoa-blabla: 3/3; fontnone: 14px \"Hoefler Text\"; text-alignleft: left; color: rgba(0, 0, 0, 1.000000); '>hello world</bla>"
        let attributedString2 = Ashton.decode(ashtonHTML2)
        XCTAssertEqual(attributedString2.string, "hello world")
    }
    
    func testDefaultAttributes() {
        let html = "<p>Hello <span style= 'font: 18px \"Helvetica Neue\"; -cocoa-font-postscriptname: \"HelveticaNeue\"; '>World</span></p>"
        let defaultFont = Font(name: "Arial", size: 12)!
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: defaultFont]
        let attributedString = Ashton.decode(html, defaultAttributes: defaultAttributes)
        let attributes1 = attributedString.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(attributes1[.font] as! Font, defaultFont)
        
        let attributes2 = attributedString.attributes(at: 6, effectiveRange: nil)
        XCTAssertNotEqual(attributes2[.font] as! Font, defaultFont)
    }

    func testCompoundCharactersEncodingWithDifferentAttributes() {
        let font = Font(name: "Thonburi", size: 12)!
        let helvetica = Font(name: "Helvetica", size: 12)!
        let firstCharacterAttributes: [NSAttributedString.Key: Any] = [.font: font,
                                                                      NSAttributedString.Key(rawValue: "NSOriginalFont"): helvetica]
        let secondCharacterAttributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedStringWithCompoundChars = NSMutableAttributedString(string: "\u{0E17}", attributes: firstCharacterAttributes)
        attributedStringWithCompoundChars.append(NSAttributedString(string: "\u{0E38}", attributes: secondCharacterAttributes))
        let html = Ashton.encode(attributedStringWithCompoundChars)
        let roundTrippedAttributedString = Ashton.decode(html, defaultAttributes: [:])
        XCTAssertEqual(roundTrippedAttributedString.string, attributedStringWithCompoundChars.string)
    }
    
    func testSpecialCharacters() {
        let string = "Hello 🌍, 😎, 🤡 - 🍺 ≤ 🍷 < 🥃"
        let attributedString = NSAttributedString(string: string)
        let html = Ashton.encode(attributedString)
        let roundTrippedAttributedString = Ashton.decode(html)
        XCTAssertEqual(attributedString.string, roundTrippedAttributedString.string)
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
}
