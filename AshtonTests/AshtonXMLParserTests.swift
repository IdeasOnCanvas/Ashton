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
        let parser = AshtonXMLParser(xmlString: sampleString)
        XCTAssertEqual(parser.parse(), "hello & world")
        
        let sampleString2 = "&apos;hello&apos; &lt;&gt; &quot;world&quot;"
        let parser2 = AshtonXMLParser(xmlString: sampleString2)
        XCTAssertEqual(parser2.parse(), "'hello' <> \"world\"")
        
        let sampleString3 = "&lfds;"
        let parser3 = AshtonXMLParser(xmlString: sampleString3)
        XCTAssertEqual(parser3.parse(), "&lfds;")
    }
    
    func testXMLParsingPerformance() {
        let rtfURL = Bundle(for: AshtonTests.self).url(forResource: "RTFText", withExtension: "rtf")!
        let attributedString =  try! NSAttributedString(url: rtfURL, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        let sampleHTML = Ashton.encode(attributedString)
        self.measure {
            let parser = AshtonXMLParser(xmlString: sampleHTML)
            _ = parser.parse()
        }
    }
}
