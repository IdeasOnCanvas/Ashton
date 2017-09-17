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

//    func testHTMLConversion() {
//		let attributedString = NSMutableAttributedString(string: "Test: Link to test. That's it")
//		attributedString.setAttributes([NSAttributedStringKey.link: "http://google.com/?a='b\"&c=<>"], range: NSRange(location: 6, length: 13))
//		//let html = attributedString.mn_HTMLRepresentation()
//		let html = AshtonHTMLWriter().htmlString(from: attributedString)
//		let convertedBack = AshtonHTMLReader().attributedString(fromHTMLString: html!)
//		//let convertedBack = NSAttributedString(htmlString: html)
//		XCTAssertEqual(convertedBack!, attributedString)
//    }

	func testBackgroundColor() {
		let attributedString = NSMutableAttributedString(string: "Test: Background Color.")
		attributedString.addAttribute(NSAttributedStringKey.backgroundColor,
		                              value: UIColor.red,
		                              range: NSRange(location: 6, length: 10))
		let referenceHtml = attributedString.mn_HTMLRepresentation()!
		let html = Ashton.encode(attributedString)
		XCTAssertEqual(referenceHtml, html)

		let convertedBack = NSAttributedString(htmlString: html)!
		XCTAssertEqual(convertedBack, attributedString)
	}

	func testParagraphSpacing() {
		let attributedString = NSMutableAttributedString(string: "Hello World.\nThis is line 2.\nThisIsLine3\n\nThis is line 4")
		let referenceHtml = attributedString.mn_HTMLRepresentation()!
		let html = Ashton.encode(attributedString)
		XCTAssertEqual(html, referenceHtml)

		let convertedBack = NSAttributedString(htmlString: referenceHtml)!
		XCTAssertEqual(convertedBack, attributedString)
	}

	func testParagraphSpacingPerformance() {
		let attributedString = NSMutableAttributedString(string: "Hello World.\nThis is line 2.\nThisIsLine3\n\nThis is line 4")

		self.measure {
			for _ in 0...10000 {
				//let html = attributedString.mn_HTMLRepresentation()!
				let html = Ashton.encode(attributedString)
			}
		}
	}
}
