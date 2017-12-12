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
	private var skipNextLineBreak: Bool = true
	private var output: NSMutableAttributedString!
	private var attributesOfLastElement: [NSAttributedStringKey: Any]? {
		guard !self.output.string.isEmpty else { return nil }

		return self.output.attributes(at: self.output.string.count - 1, effectiveRange: nil)
	}

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
		var uiUsage: String?

		func makeFont() -> Font? {
			guard let fontName = self.postScriptName ?? self.familyName else { return nil }
			guard let pointSize = self.pointSize else { return nil }

			var attributes: [FontDescriptor.AttributeName: Any] = [
				FontDescriptor.AttributeName.name: fontName
			]
			if let uiUsage = self.uiUsage {
				let uiUsageAttribute = FontDescriptor.AttributeName.init(rawValue: "NSCTFontUIUsageAttribute")
				attributes[uiUsageAttribute] = uiUsage
			}

			let fontDescriptor = FontDescriptor(fontAttributes: attributes)
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

			return Font(descriptor: fontDescriptorWithTraits ?? fontDescriptor, size: pointSize)
		}
	}

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
		guard let url = URL(string: link) else { return }

		self.currentAttributes[.link] = url
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
					guard let textDecoration = self.parseTextDecoration(from: value) else { continue }

					self.currentAttributes[textDecoration.attributedStringKey] = textDecoration.value
				case "-cocoa-underline":
					guard let underlineStyle = self.parseUnderlineStyle(from: value) else { continue }

					self.currentAttributes[.underlineStyle] = underlineStyle.rawValue
				case "-cocoa-strikethrough":
					guard let underlineStyle = self.parseUnderlineStyle(from: value) else { continue }

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

				case "-cocoa-font-uiusage":
					let scanner = Scanner(string: value)
					scanner.scanString("\"", into: nil)
					var uiusage: NSString?
					guard scanner.scanUpTo("\"", into: &uiusage) else { continue }

					fontBuilder.uiUsage = uiusage as String?

                case "text-align":
                    let alignment = self.parseAlignment(from: value)
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = alignment
                    self.currentAttributes[.paragraphStyle] = paragraphStyle
                    print("\(value)")

				default:
					print("unhandled propertyName: \(propertyName)")
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

	func parseTextDecoration(from value: String) -> (attributedStringKey: NSAttributedStringKey, value: Any)? {
		switch value {
		case "underline":
			return (.underlineStyle, NSUnderlineStyle.styleSingle.rawValue)
		case "line-through":
			return (.strikethroughStyle, NSUnderlineStyle.styleSingle.rawValue)
		default:
			print("unhandled text decoration value: \(value)")
			return nil
		}
	}

	func parseUnderlineStyle(from value: String) -> NSUnderlineStyle? {
		// TODO: create some bidirectional mapping struct to use same construct in writer and reader
		let mapping: [String: NSUnderlineStyle] = [
			"single": .styleSingle,
			"double": .styleDouble,
			"thick": .styleThick
		]
		return mapping[value]
	}

    func parseAlignment(from value: String) -> NSTextAlignment {
        switch value {
        case "left":
            return .left
        case "center":
            return .center
        case "right":
            return .right
        case "justify":
            return .justified
        default:
            return .left
        }
    }
}
