//
//  AshtonHTMLReader.swift
//  Ashton
//
//  Created by Michael Schwarz on 17.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation


final class AshtonHTMLReader: NSObject {

	func decode(_ html: Ashton.HTML) -> NSAttributedString {
		guard let data = html.data(using: .utf8) else { return NSAttributedString() }

		let parser = XMLParser(data: data)
		parser.delegate = self

		return NSAttributedString()
	}
}

extension AshtonHTMLReader: XMLParserDelegate {

}
