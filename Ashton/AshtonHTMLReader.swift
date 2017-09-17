//
//  AshtonHTMLReader.swift
//  Ashton
//
//  Created by Michael Schwarz on 17.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation


final class AshtonHTMLReader: NSObject {

	var output: NSMutableAttributedString!

	func decode(_ html: Ashton.HTML) -> NSAttributedString {
		guard let data = html.data(using: .utf8) else { return NSAttributedString() }
		self.output = NSMutableAttributedString()

		let parser = XMLParser(data: data)
		parser.delegate = self

		return self.output
	}
}

extension AshtonHTMLReader: XMLParserDelegate {

	func parserDidStartDocument(_ parser: XMLParser) {
		self.output.beginEditing()
	}

	func parserDidEndDocument(_ parser: XMLParser) {
		self.output.endEditing()
	}

	func parser(_ parser: XMLParser, foundCharacters string: String) {
		// Append string content
	}

	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		// add styles element
	}

	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		// remove element styles
	}

	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
		// handle error
	}
}
