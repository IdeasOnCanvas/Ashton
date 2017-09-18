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

		if let attribute = element.pointee.firstAttribute {
			self.parseAttributes(attribute)
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

	func parseAttributes(_ attribute: UnsafeMutablePointer<TBXMLAttribute>) {

		let name = String(cString: attribute.pointee.name)
		let value = String(cString: attribute.pointee.value)

		print("Attribute \(name) \(value)" )
		if let nextAttribute = attribute.pointee.next {
			self.parseAttributes(nextAttribute)
		}
	}
}
