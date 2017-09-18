//
//  AshtonHTMLReader.swift
//  Ashton
//
//  Created by Michael Schwarz on 17.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation
import Ashton.TBXML


final class AshtonHTMLReader: NSObject {

	private var skipNextLineBreak: Bool = true
	private var output: NSMutableAttributedString!
	private var attributesOfLastElement: [NSAttributedStringKey: Any]? {
		guard !self.output.string.isEmpty else { return nil }

		return self.output.attributes(at: self.output.string.count - 1, effectiveRange: nil)
	}

	func decode(_ html: Ashton.HTML) -> NSAttributedString {
		let wrappedHTML = "<html>\(html)</html>"
		let tbxml = try! TBXML.newTBXML(withXMLString: wrappedHTML, error: ())

		self.output = NSMutableAttributedString()
		self.parseElement(tbxml.rootXMLElement)


//		let name = TBXML.elementName(tbxml.rootXMLElement)
//		let name2 = TBXML.elementName(tbxml.rootXMLElement.pointee.firstChild)
//		let text = TBXML.text(for: tbxml.rootXMLElement.pointee.firstChild.pointee.nextSibling)
//		guard let data = wrappedHTML.data(using: .utf8) else { return NSAttributedString() }
//		self.output = NSMutableAttributedString()
//
//		let parser = XMLParser(data: data)
//		parser.shouldProcessNamespaces = false
//		parser.delegate = self
//		parser.parse()

		return self.output
	}

	func parseElement(_ element: UnsafeMutablePointer<TBXMLElement>) {
		if let elementName = TBXML.elementName(element) {
			switch elementName {
			case "p":
				guard !self.skipNextLineBreak else {
					self.skipNextLineBreak = false
					break
				}
				let linebreak = NSAttributedString(string: "\n", attributes: nil)
				self.output.append(linebreak)
			default:
				break
			}
		}

		if let text = TBXML.text(for: element) {
			self.output.append(NSAttributedString(string: text, attributes: nil))
		}

		if let firstChild = element.pointee.firstChild {
			self.parseElement(firstChild)
		}

		if let nextChild = element.pointee.nextSibling {
			self.parseElement(nextChild)
		}
	}
}

// MARK: - XMLParserDelegate

extension AshtonHTMLReader: XMLParserDelegate {

	func parserDidStartDocument(_ parser: XMLParser) {
		self.output.beginEditing()
		
	}

	func parserDidEndDocument(_ parser: XMLParser) {
		self.output.endEditing()
	}

	func parser(_ parser: XMLParser, foundCharacters string: String) {
		// add styles
		self.output.append(NSAttributedString(string: string, attributes: nil))
	}

	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		switch elementName {
		case "p":
			guard !self.skipNextLineBreak else {
				self.skipNextLineBreak = false
				return
			}
			let linebreak = NSAttributedString(string: "\n", attributes: nil)
			self.output.append(linebreak)
		default:
			break
		}
	}

	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

	}

	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
		print("error happened: \(parseError)")
	}
}
