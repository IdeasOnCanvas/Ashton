//
//  AshtonHTMLReader.swift
//  Ashton
//
//  Created by Michael Schwarz on 17.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation
import Ashton.TBXML
#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif


final class AshtonHTMLReader: NSObject {

	private var currentAttributes: [NSAttributedStringKey: Any] = [:]
	private var output: NSMutableAttributedString!

	func decode(_ html: Ashton.HTML) -> NSAttributedString {
		let wrappedHTML = "<html>\(html)</html>"

		let tbxml = try! TBXML(xmlString: wrappedHTML, error: ())

		self.output = NSMutableAttributedString()
		self.parseElement(tbxml.rootXMLElement)

		return self.output
	}
}

// MARK: - Private

private extension AshtonHTMLReader {

	struct FontBuilder {
		var familyName: String?
		var postScriptName: String?
		var isBold: Bool = false
		var isItalic: Bool = false
		var pointSize: CGFloat?

        static let fontCache = NSCache<NSString, Font>()

		func makeFont() -> Font? {
			guard let fontName = self.postScriptName ?? self.familyName else { return nil }
			guard let pointSize = self.pointSize else { return nil }

            let cacheKey = "\(fontName)\(pointSize)\(self.isItalic)\(self.isBold)"
            if let cachedFont = FontBuilder.fontCache.object(forKey: cacheKey as NSString) { return cachedFont }

			let fontDescriptor = FontDescriptor(fontAttributes: [FontDescriptor.AttributeName.name: fontName])
			let fontDescriptorWithTraits: FontDescriptor?

            var symbolicTraits = FontDescriptorSymbolicTraits()
            if self.postScriptName == nil {
                #if os(iOS)
                    if self.isBold { symbolicTraits.insert(.traitBold) }
                    if self.isItalic { symbolicTraits.insert(.traitItalic) }
                #elseif os(macOS)
                    if self.isBold { symbolicTraits.insert(.bold) }
                    if self.isItalic { symbolicTraits.insert(.italic) }
                #endif
                fontDescriptorWithTraits = fontDescriptor.withSymbolicTraits(symbolicTraits)
			} else {
				fontDescriptorWithTraits = nil
			}

            #if os(iOS)
                let font = Font(descriptor: fontDescriptorWithTraits ?? fontDescriptor, size: pointSize)
            #elseif os(macOS)
                guard let font = Font(descriptor: fontDescriptorWithTraits ?? fontDescriptor, size: pointSize) else { return nil }
            #endif

            FontBuilder.fontCache.setObject(font, forKey: cacheKey as NSString)
			return font
		}
	}

	func append(_ string: String) {
		if self.currentAttributes.isEmpty == false {
			self.output.append(NSAttributedString(string: string, attributes: self.currentAttributes))
		} else {
			self.output.append(NSAttributedString(string: string))
		}
	}

	func parseElement(_ element: UnsafeMutablePointer<TBXMLElement>) {
		let attributesBeforeElement = self.currentAttributes
		if let attribute = element.pointee.firstAttribute {
			self.parseAttributes(attribute)
		}

		if let text = TBXML.text(for: element) {
			self.append(text.stringByRemovingHTMLEncoding)
		}

		if let firstChild = element.pointee.firstChild {
			self.parseElement(firstChild)
		}

		if let nextChild = element.pointee.nextSibling {
            let elementName = TBXML.elementName(element)
            if elementName == "p" { self.append("\n") }

            self.currentAttributes = attributesBeforeElement
			self.parseElement(nextChild)
        }
	}

	func parseAttributes(_ attribute: UnsafeMutablePointer<TBXMLAttribute>) {
		let name = String(cString: attribute.pointee.name)
		let value = String(cString: attribute.pointee.value)

		switch name {
		case "style":
			self.parseStyleString(value)
		case "href":
			self.parseLink(value)
		default:
			print("unhandled attribute: \(value)")
		}

		if let nextAttribute = attribute.pointee.next {
			self.parseAttributes(nextAttribute)
		}
	}

	func parseLink(_ link: String) {
		self.currentAttributes[.link] = link.stringByRemovingHTMLEncoding
	}

	func parseStyleString(_ styleString: String) {
		let scanner = Scanner(string: styleString)
		var propertyName: NSString? = nil
		var value: NSString? = nil
		var fontBuilder = FontBuilder()
		scanner.charactersToBeSkipped = CharacterSet(charactersIn: ": ;")

		while (scanner.scanUpTo(":", into: &propertyName) && scanner.scanUpTo(";", into: &value)) {
			if let propertyName = (propertyName as String?), let value = (value as String?) {
				switch propertyName {
				case "background-color":
					guard let color = self.parseCSSColor(from: value) else { continue }

					self.currentAttributes[.backgroundColor] = color
				case "color":
					guard let color = self.parseCSSColor(from: value) else { continue }

					self.currentAttributes[.foregroundColor] = color
				case "-cocoa-strikethrough-color":
					guard let color = self.parseCSSColor(from: value) else { continue }

					self.currentAttributes[.strikethroughColor] = color
				case "-cocoa-underline-color":
					guard let color = self.parseCSSColor(from: value) else { continue }

					self.currentAttributes[.underlineColor] = color
				case "text-decoration":
                    guard let textDecorationType = Mappings.TextDecoration.decode[value] else { continue }

					self.currentAttributes[textDecorationType] = NSUnderlineStyle.styleSingle.rawValue
				case "-cocoa-underline":
					guard let underlineStyle = Mappings.UnderlineStyle.decode[value] else { continue }

					self.currentAttributes[.underlineStyle] = underlineStyle.rawValue
				case "-cocoa-strikethrough":
					guard let underlineStyle = Mappings.UnderlineStyle.decode[value] else { continue }

					self.currentAttributes[.strikethroughStyle] = underlineStyle.rawValue
				case "font":
					let scanner = Scanner(string: value)
					scanner.charactersToBeSkipped = CharacterSet(charactersIn: ", ")
					fontBuilder.isBold = scanner.scanString("bold", into: nil)
					fontBuilder.isItalic = scanner.scanString("italic", into: nil)
					var pointSize: Int = 0
					guard scanner.scanInt(&pointSize) else { continue }

					fontBuilder.pointSize = CGFloat(pointSize)
					scanner.scanString("px", into: nil)
					scanner.scanString("\"", into: nil)
					var family: NSString?
					guard scanner.scanUpTo("\"", into: &family) else { continue }
					guard let fontFamily = (family as String?) else { continue }

					fontBuilder.familyName = fontFamily

                case "-cocoa-font-postscriptname":
					let scanner = Scanner(string: value)
					scanner.scanString("\"", into: nil)
					var postscriptName: NSString?
					guard scanner.scanUpTo("\"", into: &postscriptName) else { continue }

					fontBuilder.postScriptName = postscriptName as String?

                case "text-align":
                    guard let alignment = Mappings.TextAlignment.decode[value] else { continue }

                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = alignment
                    self.currentAttributes[.paragraphStyle] = paragraphStyle

                case "-cocoa-baseline-offset":
                    guard let offset = Float(value)  else { return }

                    self.currentAttributes[.baselineOffset] = offset
                case "-cocoa-vertical-align":
                    guard let offset = Float(value)  else { return }

                    self.currentAttributes[.superscript] = offset
                case "vertical-align":
                    // skip, if we assigned already via -cocoa-vertical-align
                    guard self.currentAttributes[.superscript] == nil else { return }

                    switch value {
                    case "super":
                        self.currentAttributes[.superscript] = 1
                    case "sub":
                        self.currentAttributes[.superscript] = -1
                    default:
                        break
                    }
				default:
                    break
				}
			}
		}
		if let font = fontBuilder.makeFont() {
			self.currentAttributes[.font] = font
		}
	}

	func parseCSSColor(from string: String) -> Color? {
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

		return Color(red: CGFloat(rValue) / 255.0, green: CGFloat(gValue) / 255.0, blue: CGFloat(bValue) / 255.0, alpha: CGFloat(alpha))
	}
}

// MARK: - String

private extension String {

    static let mapping: [String: String] = [
        "&amp;": "&",
        "&quot;": "\"",
        "&apos;": "'",
        "&lt;": "<",
        "&gt;": ">",
        "<br />": "\n"
    ]

    var stringByRemovingHTMLEncoding: String {
        guard self.contains("&") else { return self }

        var newString = self
        for (escapeString, escapedSymbol) in String.mapping {
            newString = newString.replacingOccurrences(of: escapeString, with: escapedSymbol)
        }

        return newString
    }
}
