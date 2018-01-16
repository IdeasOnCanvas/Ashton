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
    
    func testXMLParsingPerformance() {
        let rtfURL = Bundle(for: AshtonTests.self).url(forResource: "RTFText", withExtension: "rtf")!
        let attributedString =  try! NSAttributedString(url: rtfURL, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        let sampleHTML = Ashton.encode(attributedString) + ""
        let delegate = DummyParserDelegate()
        self.measure {
            let parser = AshtonXMLParser(xmlString: sampleHTML)
            parser.delegate = delegate
            parser.parse()
            print(delegate)
        }
    }
}

// MARK: - Private

private extension AshtonXMLParserTests {
    
    final class DummyParserDelegate: AshtonXMLParserDelegate {
        
        var content: String = ""
        
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
