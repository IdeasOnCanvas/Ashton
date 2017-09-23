//
//  AshtonHTMLReader.swift
//  Ashton
//
//  Created by Michael Schwarz on 17.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation
import UIKit
import Ashton.TBXML


final class AshtonHTMLReader: NSObject {

    private var currentAttributes: [NSAttributedStringKey: Any] = [:]
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
}

// MARK: - Private

private extension AshtonHTMLReader {

    func append(_ string: String) {
        if !self.currentAttributes.isEmpty {
            self.output.append(NSAttributedString(string: string, attributes: self.currentAttributes))
        } else {
            self.output.append(NSAttributedString(string: string))
        }
    }

    func parseElement(_ element: UnsafeMutablePointer<TBXMLElement>) {
        if let elementName = TBXML.elementName(element) {
            switch elementName {
            case "p":
                guard !self.skipNextLineBreak else {
                    self.skipNextLineBreak = false
                    break
                }
                self.append("\n")
            default:
                break
            }
        }

        let attributesBeforeElement = self.currentAttributes
        if let attribute = element.pointee.firstAttribute {
            self.parseAttributes(attribute)
        }

        if let text = TBXML.text(for: element) {
            self.append(text)
        }

        if let firstChild = element.pointee.firstChild {
            self.parseElement(firstChild)
        }

        self.currentAttributes = attributesBeforeElement

        if let nextChild = element.pointee.nextSibling {
            self.parseElement(nextChild)
        }
    }

    func parseAttributes(_ attribute: UnsafeMutablePointer<TBXMLAttribute>) {
        let name = String(cString: attribute.pointee.name)
        let value = String(cString: attribute.pointee.value)

        switch name {
        case "style":
            self.parseStyleString(value)
        default:
            print("unhandled attribute: \(value)")
        }

        if let nextAttribute = attribute.pointee.next {
            self.parseAttributes(nextAttribute)
        }
    }

    func parseStyleString(_ styleString: String) {
        let scanner = Scanner(string: styleString)
        var propertyName: NSString? = nil
        var value: NSString? = nil
		scanner.charactersToBeSkipped = CharacterSet(charactersIn: ": ")
        scanner.scanUpTo(":", into: &propertyName)
        scanner.scanUpTo(";", into: &value)

        if let propertyName = (propertyName as String?), let value = (value as String?) {
            switch (propertyName as String) {
            case "background-color":
                guard let color = self.parseCSSColor(from: value) else { return }

                self.currentAttributes[.backgroundColor] = color
			case "color":
				 guard let color = self.parseCSSColor(from: value) else { return }

				self.currentAttributes[.foregroundColor] = color
            default:
                print("unhandled property: \(value)")

            }
        }
    }

    func parseCSSColor(from string: String) -> UIColor? {
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: ", ")
        var rValue: Int = 0
        var gValue: Int = 0
        var bValue: Int = 0
        var alpha: Float = -1

        guard scanner.scanString("rgba(", into: nil) else { return nil }
        guard scanner.scanInt(&rValue) else { return nil }
        guard scanner.scanInt(&gValue) else { return nil }
        guard scanner.scanInt(&bValue) else { return nil }
        guard scanner.scanFloat(&alpha) else { return nil }

        return UIColor(red: CGFloat(rValue) / 255.0, green: CGFloat(gValue) / 255.0, blue: CGFloat(bValue) / 255.0, alpha: CGFloat(alpha))
    }
}
