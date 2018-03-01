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
        let sampleString = "<p><span style='bla:fasdf;'> hello</span> &amp; world<dummy> not this </dummy></p>"
        let delegate = DummyParserDelegate()
        let parser = AshtonXMLParser()
        parser.delegate = delegate
        parser.parse(string: sampleString)
        XCTAssertEqual(delegate.closedTags, 3)
        XCTAssertEqual(delegate.openedTags.map { $0.name }, [.p, .span, .ignored])
    }

    func testParsingWithoutSemicolonTerminatedAttributes() {
        let result = self.parseString("<html>\n<p style=\"margin: 0.0px 0.0px 0.0px 0.0px\"><font>These are the notes of Subtopic 2</font>\n</p>\n\n</html>")
        XCTAssertEqual(result, "\nThese are the notes of Subtopic 2\n\n\n")

        let result2 = self.parseString("<html>\n<p style=\"margin: 0.0px 0.0px 0.0px 0.0px\"><font color=\"#000000\" style=\"font-kerning: none; color: #000000; -webkit-text-stroke: 0px #000000\">Node with note and URL</font>\n</p>\n\n</html>")
        XCTAssertEqual(result2, "\nThese are the notes of Subtopic 2\n\n\n")
    }

    func testSingleStyleAttributesParsing() {
        let sampleString = "<span style='background-color:rgba(52, 72, 83, 1.000000);'>Test</span>"

        let delegate = DummyParserDelegate()
        let parser = AshtonXMLParser()
        parser.delegate = delegate
        parser.parse(string: sampleString)
        XCTAssertEqual(delegate.openedTags.count, 1)

        let attributes = delegate.openedTags.first!.attributes!
        XCTAssertEqual(attributes.values.count, 1)
        XCTAssertTrue(attributes[.backgroundColor] is Color)
    }

    func testMultipleStyleAttributesParsing() {
        let styleString = "<span style='color: rgba(52, 72, 83, 1.000000); font: 18px \"\"; -cocoa-font-postscriptname: \"Arial\"; '>\\UF016</span><span style='color: rgba(52, 72, 83, 1.000000); font: 18px \"Helvetica Neue\"; -cocoa-font-postscriptname: \"HelveticaNeue\"; '>Hello World</span>"
        let delegate = DummyParserDelegate()
        let parser = AshtonXMLParser()
        parser.delegate = delegate
        parser.parse(string: styleString)
        XCTAssertEqual(delegate.openedTags.count, 2)

        let attributes = delegate.openedTags.first!.attributes!
        XCTAssertEqual(attributes.count, 2)
    }

    func testHrefParsing() {
        let sampleString = "<a style='font: bold 16px \"Helvetica\"; -cocoa-font-postscriptname: \"Helvetica-Bold\"; -cocoa-underline-color: rgba(127, 0, 127, 1.000000); ' href='http://google.com'>h</a>"
        let delegate = DummyParserDelegate()
        let parser = AshtonXMLParser()
        parser.delegate = delegate
        parser.parse(string: sampleString)
        XCTAssertEqual(delegate.openedTags.count, 1)

        let attributes = delegate.openedTags.first!.attributes!
        XCTAssertEqual(attributes.count, 3)
        XCTAssertEqual(attributes[.link] as! URL, URL(string: "http://google.com")!)
    }
    
    func testXMLParsingPerformance() {
        let rtfURL = Bundle(for: AshtonTests.self).url(forResource: "RTFText", withExtension: "rtf")!
        let attributedString =  try! NSAttributedString(url: rtfURL, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        let sampleHTML = Ashton.encode(attributedString) + ""
        let delegate = DummyParserDelegate()
        let parser = AshtonXMLParser()
        self.measure {
            parser.delegate = delegate
            parser.parse(string: sampleHTML)
        }
    }
}

// MARK: - Private

private extension AshtonXMLParserTests {
    
    final class DummyParserDelegate: AshtonXMLParserDelegate {
        var openedTags: [(name: AshtonXMLParser.Tag, attributes: [NSAttributedStringKey: Any]?)] = []
        var content: String = ""
        var closedTags = 0
        
        func didOpenTag(_ parser: AshtonXMLParser, name: AshtonXMLParser.Tag, attributes: [NSAttributedStringKey: Any]?) {
            self.openedTags.append((name, attributes))
        }
        
        func didCloseTag(_ parser: AshtonXMLParser) {
            closedTags += 1
        }
        
        func didParseContent(_ parser: AshtonXMLParser, string: String) {
            self.content.append(string)
        }
    }
    
    func parseString(_ string: String) -> String {
        let parser = AshtonXMLParser()
        let dummyDelegate = DummyParserDelegate()
        parser.delegate = dummyDelegate
        parser.parse(string: string)
        return dummyDelegate.content
    }
}
