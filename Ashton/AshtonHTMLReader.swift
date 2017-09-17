//
//  AshtonHTMLReader.swift
//  Ashton
//
//  Created by Michael Schwarz on 17.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation


final class AshtonHTMLReader: NSObject {

	private var output: NSMutableAttributedString!
	private var attributesOfLastElement: [NSAttributedStringKey: Any]? {
		guard !self.output.string.isEmpty else { return nil }

		return self.output.attributes(at: self.output.string.count - 1, effectiveRange: nil)
	}

	func decode(_ html: Ashton.HTML) -> NSAttributedString {
		let wrappedHTML = "<html>\(html)</html>"
		guard let data = wrappedHTML.data(using: .utf8) else { return NSAttributedString() }
		self.output = NSMutableAttributedString()

		let parser = XMLParser(data: data)
		parser.delegate = self
		parser.parse()

		return self.output
	}
}

// MARK: - XMLParserDelegate

extension AshtonHTMLReader: XMLParserDelegate {

	func parserDidStartDocument(_ parser: XMLParser) {
		self.output.beginEditing()
	}

	func parserDidEndDocument(_ parser: XMLParser) {
		if self.output.string.hasPrefix("\n") {
			self.output.deleteCharacters(in: NSRange(location: 0, length: 1))
		}
		self.output.endEditing()
	}

	func parser(_ parser: XMLParser, foundCharacters string: String) {
		// add styles
		self.output.append(NSAttributedString(string: string, attributes: nil))
	}

	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		switch elementName {
		case "html":
			break
		case "p":
			let linebreak = NSAttributedString(string: "\n", attributes: self.attributesOfLastElement)
			self.output.append(linebreak)
		default:
			assertionFailure("did not handle \(elementName)")
		}
	}

	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		// remove element styles
	}

	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
		print("error happened: \(parseError)")
	}
}
