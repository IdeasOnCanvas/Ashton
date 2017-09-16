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
		let html = attributedString.mn_HTMLRepresentation()!
		let convertedBack = NSAttributedString(htmlString: html)!
		XCTAssertEqual(convertedBack, attributedString)
	}
}
