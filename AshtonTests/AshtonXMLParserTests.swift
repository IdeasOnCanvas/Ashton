//
//  AshtonXMLParserTests.swift
//  AshtonTests
//
//  Created by Michael Schwarz on 16.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

import XCTest
@testable import Ashton


final class AshtonXMLParserTests: XCTestCase {
    
    func testEscapeSubstitution() {
        let sampleString = "hello &amp; world"
        XCTAssertEqual(self.parseString(sampleString), "hello & world")
        
        let sampleString2 = "&apos;hello&apos; &lt;&gt; &quot;world&quot;"
        XCTAssertEqual(self.parseString(sampleString2), "'hello' <> \"world\"")
        
        let sampleString3 = "&lfds;"
        XCTAssertEqual(self.parseString(sampleString3), "&lfds;")
        
        let sampleString4 = "&lfdsfasdfasdf"
        XCTAssertEqual(self.parseString(sampleString4), "&lfdsfasdfasdf")
    }

    func testTagParsing() {
        let sampleString = "<p><span style='bla'> hello</span> &amp; world<dummy> not this </dummy></p>"
        let delegate = DummyParserDelegate()
        let parser = AshtonXMLParser(xmlString: sampleString)
        parser.delegate = delegate
        parser.parse()
        XCTAssertEqual(delegate.closedTags, 3)
        XCTAssertEqual(delegate.openedTags.map { $0.0 }, [.p, .span, .ignored])
    }

    func testSingleStyleAttributesParsing() {
        let sampleString = "<span style='background-color:rgba(52, 72, 83, 1.000000);'>Test</span>"

        let delegate = DummyParserDelegate()
        let parser = AshtonXMLParser(xmlString: sampleString)
        parser.delegate = delegate
        parser.parse()
        XCTAssertEqual(delegate.openedTags.count, 1)

        let attributes = delegate.openedTags.first!.1![.style]!
        XCTAssertEqual(attributes.values.count, 1)
        XCTAssertEqual(attributes[AshtonXMLParser.AttributeKeys.Style.backgroundColor], "rgba(52, 72, 83, 1.000000)")
    }

    func testMultipleStyleAttributesParsing() {
        let styleString = "<span style='color: rgba(52, 72, 83, 1.000000); font: 18px \"\"; -cocoa-font-postscriptname: \"Arial\"; '>\\UF016</span><span style='color: rgba(52, 72, 83, 1.000000); font: 18px \"Helvetica Neue\"; -cocoa-font-postscriptname: \"HelveticaNeue\"; '>Hello World</span>"
        let delegate = DummyParserDelegate()
        let parser = AshtonXMLParser(xmlString: styleString)
        parser.delegate = delegate
        parser.parse()
        XCTAssertEqual(delegate.openedTags.count, 2)

        let attributes = delegate.openedTags.first!.1![.style]!
        XCTAssertEqual(attributes.count, 3)
        XCTAssertEqual(attributes[AshtonXMLParser.AttributeKeys.Style.color], "rgba(52, 72, 83, 1.000000)")
        XCTAssertEqual(attributes[AshtonXMLParser.AttributeKeys.Style.font], "18px \"\"")
        XCTAssertEqual(attributes[AshtonXMLParser.AttributeKeys.Style.Cocoa.fontPostScriptName], "\"Arial\"")
    }

    func testHrefParsing() {
        let sampleString = "<a style='font: bold 16px \"Helvetica\"; -cocoa-font-postscriptname: \"Helvetica-Bold\"; -cocoa-underline-color: rgba(127, 0, 127, 1.000000); ' href='http://google.com'>h</a>"
        let delegate = DummyParserDelegate()
        let parser = AshtonXMLParser(xmlString: sampleString)
        parser.delegate = delegate
        parser.parse()
        XCTAssertEqual(delegate.openedTags.count, 1)

        let styleAttributes = delegate.openedTags.first!.1![.style]!
        XCTAssertEqual(styleAttributes.count, 3)
    }
    
    func testXMLParsingPerformance() {
        let rtfURL = Bundle(for: AshtonTests.self).url(forResource: "RTFText", withExtension: "rtf")!
        let attributedString =  try! NSAttributedString(url: rtfURL, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        let sampleHTML = Ashton.encode(attributedString) + ""
        let delegate = DummyParserDelegate()
        self.measure {
            let parser = AshtonXMLParser(xmlString: sampleHTML)
            parser.delegate = delegate
            parser.parse()
        }
    }
}

// MARK: - Private

private extension AshtonXMLParserTests {
    
    final class DummyParserDelegate: AshtonXMLParserDelegate {
        var openedTags: [(AshtonXMLParser.Tag, [AshtonXMLParser.Attribute: [AshtonXMLParser.AttributeKey: String]]?)] = []
        var content: String = ""
        var closedTags = 0
        var attributes: [AshtonXMLParser.AttributeKey: String] = [:]
        
        func didOpenTag(_ tag: AshtonXMLParser.Tag, attributes: [AshtonXMLParser.Attribute: [AshtonXMLParser.AttributeKey: String]]?) {
            self.openedTags.append((tag, attributes))
        }
        
        func didCloseTag() {
            closedTags += 1
        }
        
        func didParseContent(_ string: String) {
            self.content.append(string)
        }
    }
    
    func parseString(_ string: String) -> String {
        let parser = AshtonXMLParser(xmlString: string)
        let dummyDelegate = DummyParserDelegate()
        parser.delegate = dummyDelegate
        parser.parse()
        return dummyDelegate.content
    }
}
