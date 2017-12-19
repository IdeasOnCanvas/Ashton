//
//  AshtonHTMLWriter.swift
//  Ashton
//
//  Created by Michael Schwarz on 16.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation
#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif


final class AshtonHTMLWriter {

    func encode(_ attributedString: NSAttributedString) -> Ashton.HTML {
        let string = attributedString.string
        let paragraphRanges = self.getParagraphRanges(from: string)

        var html = String()
        for paragraphRange in paragraphRanges {
            var paragraphContent = String()
            let nsParagraphRange = NSRange(paragraphRange, in: string)
            var paragraphTag = HTMLTag(defaultName: .p, attributes: [:], ignoreParagraphStyles: false)
            attributedString.enumerateAttributes(in: nsParagraphRange,
                                                 options: .longestEffectiveRangeNotRequired, using: { attributes, nsrange, _ in
                                                    let paragraphStyle = attributes.filter { $0.key == .paragraphStyle }
                                                    paragraphTag.addAttributes(paragraphStyle)

                                                    if nsParagraphRange.length == nsrange.length {
                                                        paragraphTag.addAttributes(attributes)
                                                        paragraphContent += String(attributedString.string[paragraphRange]).htmlEscaped
                                                    } else {
                                                        guard let range = Range(nsrange, in: attributedString.string) else { return }

                                                        var tag = HTMLTag(defaultName: .span, attributes: attributes, ignoreParagraphStyles: true)
                                                        paragraphContent += tag.parseOpenTag()
                                                        paragraphContent += String(attributedString.string[range]).htmlEscaped
                                                        paragraphContent += tag.makeCloseTag()
                                                    }
            })

            html += paragraphTag.parseOpenTag() + paragraphContent + paragraphTag.makeCloseTag()
        }

        return html
    }
}

// MARK: - Private

private extension AshtonHTMLWriter {

    func getParagraphRanges(from string: String) -> [Range<String.Index>] {
        var (paragraphStart, paragraphEnd, contentsEnd) = (string.startIndex, string.startIndex, string.startIndex)
        var ranges = [Range<String.Index>]()
        let length = string.endIndex

        while paragraphEnd < length {
            string.getParagraphStart(&paragraphStart, end: &paragraphEnd, contentsEnd: &contentsEnd, for: paragraphEnd...paragraphEnd)
            ranges.append(paragraphStart..<contentsEnd)
        }
        return ranges
    }
}

private struct HTMLTag {

    enum Name: String {
        case p
        case span
        case a

        func openTag(with attributes: String...) -> String {
            var attributesString = ""
            for attribute in attributes {
                if attribute.isEmpty { continue }

                attributesString += " " + attribute
            }
            return "<\(self.rawValue)\(attributesString)>"
        }

        func closeTag() -> String {
            return "</\(self.rawValue)>"
        }
    }

    private var hasParsedLinks: Bool = false

    // MARK: - Properties

    let defaultName: Name
    var attributes: [NSAttributedStringKey: Any]
    let ignoreParagraphStyles: Bool

    init(defaultName: Name, attributes: [NSAttributedStringKey: Any], ignoreParagraphStyles: Bool) {
        self.defaultName = defaultName
        self.attributes = attributes
        self.ignoreParagraphStyles = ignoreParagraphStyles
    }

    mutating func addAttributes(_ attributes: [NSAttributedStringKey: Any]?) {
        attributes?.forEach { (key, value) in
            self.attributes[key] = value
        }
    }

    mutating func parseOpenTag() -> String {
        guard !self.attributes.isEmpty else { return self.defaultName.openTag() }

        var styles: [String: String] = [:]
        var cocoaStyles: [String: String] = [:]
        var links = ""

        self.attributes.forEach { key, value in
            switch key {
            case .backgroundColor:
                guard let color = value as? Color else { return }

                styles["background-color"] = self.makeCSSrgba(for: color)
            case .foregroundColor:
                guard let color = value as? Color else { return }

                styles["color"] = self.makeCSSrgba(for: color)
            case .underlineStyle:
                guard let underlineStyle = self.underlineStyle(from: value) else { return }

                styles["text-decoration"] = "underline"
                cocoaStyles["-cocoa-underline"] = String(underlineStyle)
            case .underlineColor:
                guard let color = value as? Color else { return }

                cocoaStyles["-cocoa-underline-color"] = self.makeCSSrgba(for: color)
            case .strikethroughColor:
                guard let color = value as? Color else { return }

                cocoaStyles["-cocoa-strikethrough-color"] = self.makeCSSrgba(for: color)
            case .strikethroughStyle:
                guard let underlineStyle = self.underlineStyle(from: value) else { return }

                styles["text-decoration"] = "line-through"
                cocoaStyles["-cocoa-strikethrough"] = String(underlineStyle)
            case .font:
                guard let font = value as? Font else { return }


                let fontDescriptor = font.fontDescriptor

                var fontStyle = ""
                #if os(iOS)
                    if fontDescriptor.symbolicTraits.contains(.traitBold) {
                        fontStyle += "bold "
                    }
                    if fontDescriptor.symbolicTraits.contains(.traitItalic) {
                        fontStyle += "italic "
                    }
                #elseif os(macOS)
                    if fontDescriptor.symbolicTraits.contains(.bold) {
                        fontStyle += "bold "
                    }
                    if fontDescriptor.symbolicTraits.contains(.italic) {
                        fontStyle += "italic "
                    }
                #endif

                fontStyle += String(format: "%gpx ", fontDescriptor.pointSize)
                fontStyle += "\"\(font.cpFamilyName)\""

                styles["font"] = fontStyle
                cocoaStyles["-cocoa-font-postscriptname"] = "\"\(fontDescriptor.cpPostscriptName)\""
            case .paragraphStyle:
                guard self.ignoreParagraphStyles == false else { return }
                guard let paragraphStyle = value as? NSParagraphStyle else { return }

                styles["text-align"] = paragraphStyle.alignment.htmlAttributeValue
            case .baselineOffset:
                guard let offset = value as? Float else { return }

                cocoaStyles["-cocoa-baseline-offset"] = String(format: "%.0f", offset)
            case NSAttributedStringKey(rawValue: "NSSuperScript"):
                guard let offset = value as? Int, offset != 0 else { return }

                let verticalAlignment = offset > 0 ? "super" : "sub"
                styles["vertical-align"] = String(verticalAlignment)
                cocoaStyles["-cocoa-vertical-align"] = String(offset)
            case .link:
                let link: String
                switch value {
                case let urlString as String:
                    link = urlString
                case let url as URL:
                    link = url.absoluteString
                default:
                    return
                }

                links = "href='\(link.htmlEscaped)'"
                self.hasParsedLinks = true
            default:
                assertionFailure("did not handle \(key)")
            }
        }

        if styles.isEmpty && cocoaStyles.isEmpty && links.isEmpty {
            return self.defaultName.openTag()
        }

        var openTag = ""
        var styleAttributes = ""
        do {
            let separator = "; "
            let styleDictionaryTransform: ([String: String]) -> [String] = { return $0.sorted(by: <).map { "\($0): \($1)" } }
            let styleString = (styleDictionaryTransform(styles) + styleDictionaryTransform(cocoaStyles)).joined(separator: separator)
            if styleString.isEmpty == false {
                styleAttributes = "style='\(styleString)\(separator)'"
            }
        }

        if self.hasParsedLinks {
            if self.defaultName == .p {
                openTag += self.defaultName.openTag(with: styleAttributes)
                openTag += Name.a.openTag(with: links)
            } else {
                openTag += Name.a.openTag(with: styleAttributes, links)
            }
        } else {
            openTag += self.defaultName.openTag(with: styleAttributes)
        }

        return openTag
    }

    private static let styleAttributes: Set<NSAttributedStringKey> = [
        .font, .strikethroughStyle, .strikethroughColor, .underlineColor, .underlineStyle, .foregroundColor, .backgroundColor
    ]

    func makeCloseTag() -> String {
        if self.hasParsedLinks {
            if self.defaultName == .p {
                return Name.a.closeTag() + self.defaultName.closeTag()
            } else {
                return Name.a.closeTag()
            }
        } else {
            return self.defaultName.closeTag()
        }
    }

    // MARK: - Private

    private func compareStyleTags(tags: (tag1: String, tag2: String)) -> Bool {
        return tags.tag1 > tags.tag2
    }

    private func makeCSSrgba(for color: Color) -> String {
        var (red, green, blue): (CGFloat, CGFloat, CGFloat)
        let alpha = color.cgColor.alpha
        if color.cgColor.numberOfComponents == 2 {
            let monochromeValue = color.cgColor.components?[0] ?? 0
            (red, green, blue) = (monochromeValue, monochromeValue, monochromeValue)
        } else if color.cgColor.numberOfComponents == 4 {
            red = color.cgColor.components?[0] ?? 0
            green = color.cgColor.components?[1] ?? 0
            blue = color.cgColor.components?[2] ?? 0
        } else {
            (red, green, blue) = (0, 0, 0)
        }

        return "rgba(\(Int(red * 255.0)), \(Int(green * 255.0)), \(Int(blue * 255.0)), \(String(format: "%.6f", alpha)))"
    }

    private func underlineStyle(from value: Any) -> String? {
        guard let rawValue = value as? Int else { return nil  }
        guard let underlineStyle = NSUnderlineStyle(rawValue: rawValue) else { return nil }

        return Mappings.UnderlineStyle.encode[underlineStyle]
    }
}

// MARK: - String

private extension String {

    var htmlEscaped: String {
        guard self.contains(where: { Character.mapping[$0] != nil }) else { return self }
 
        return self.reduce("") { $0 + $1.escaped }
    }
}

private extension Character {

    static let mapping: [Character: String] = [
        "&": "&amp;",
        "\"": "&quot;",
        "'": "&apos;",
        "<": "&lt;",
        ">": "&gt;",
        "\n": "<br />"
    ]

    var escaped: String {
        return Character.mapping[self] ?? String(self)
    }
}

// MARK: - NSTextAlignment

private extension NSTextAlignment {

    var htmlAttributeValue: String {
        switch self {
        case .center:
            return "center"
        case .justified:
            return "justify"
        case .right:
            return "right"
        case .left:
            return "left"
        case .natural:
            return "left"
        }
    }
}
