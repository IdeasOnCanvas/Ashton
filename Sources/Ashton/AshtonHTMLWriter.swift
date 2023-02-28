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


public final class AshtonHTMLWriter {

    // MARK: - Lifecycle

    public init() {}

    // MARK: - AshtonHTMLWriter

    public func encode(_ attributedString: NSAttributedString) -> Ashton.HTML {
        let string = attributedString.string
        let paragraphRanges = self.getParagraphRanges(from: string)
        var html = String()
        for paragraphRange in paragraphRanges {
            var paragraphContent = String()
            var nsParagraphRange = NSRange(paragraphRange, in: string)
            var paragraphTag = HTMLTag(defaultName: .p, attributes: [:], ignoreParagraphStyles: false)

            // We add an additional character to the paragraph range to get the parsed paragraph separator (e.g \n)
            if paragraphRange.isEmpty && paragraphRanges.count > 0 && paragraphRange == paragraphRanges.last {
                let fullInputStringLength = (string as NSString).length
                if fullInputStringLength >= nsParagraphRange.upperBound + 1 {
                    nsParagraphRange.length = nsParagraphRange.length + 1
                }
            }
            // We use `attributedString.string as NSString` casts and NSRange ranges in the block because
            // we experienced outOfBounds crashes when converting NSRange to Range and using it on swift string
            attributedString.enumerateAttributes(in: nsParagraphRange,
                                                 options: .longestEffectiveRangeNotRequired, using: { attributes, nsrange, _ in
                                                    let paragraphStyle = attributes.filter { $0.key == .paragraphStyle }
                                                    paragraphTag.addAttributes(paragraphStyle)

                                                    let nsString = attributedString.string as NSString
                                                    if nsParagraphRange.length == nsrange.length {
                                                        paragraphTag.addAttributes(attributes)
                                                        paragraphContent += String(nsString.substring(with: nsrange)).htmlEscaped
                                                    } else {
                                                        var tag = HTMLTag(defaultName: .span, attributes: attributes, ignoreParagraphStyles: true)
                                                        paragraphContent += tag.parseOpenTag()
                                                        paragraphContent += String(nsString.substring(with: nsrange)).htmlEscaped
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
    var attributes: [NSAttributedString.Key: Any]
    let ignoreParagraphStyles: Bool

    init(defaultName: Name, attributes: [NSAttributedString.Key: Any], ignoreParagraphStyles: Bool) {
        self.defaultName = defaultName
        self.attributes = attributes
        self.ignoreParagraphStyles = ignoreParagraphStyles
    }

    mutating func addAttributes(_ attributes: [NSAttributedString.Key: Any]?) {
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
                guard let intValue = value as? Int else { return }
                guard let underlineStyle = Mappings.UnderlineStyle.encode[intValue] else { return }

                styles["text-decoration"] = (styles["text-decoration"] ?? "").stringByAppendingAttributeValue("underline")
                cocoaStyles["-cocoa-underline"] = underlineStyle
            case .underlineColor:
                guard let color = value as? Color else { return }

                cocoaStyles["-cocoa-underline-color"] = self.makeCSSrgba(for: color)
            case .strikethroughColor:
                guard let color = value as? Color else { return }

                cocoaStyles["-cocoa-strikethrough-color"] = self.makeCSSrgba(for: color)
            case .strikethroughStyle:
                guard let intValue = value as? Int else { return }
                guard let underlineStyle = Mappings.UnderlineStyle.encode[intValue] else { return }

                styles["text-decoration"] = "line-through".stringByAppendingAttributeValue(styles["text-decoration"])
                cocoaStyles["-cocoa-strikethrough"] = underlineStyle
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

                if let fontFeatures = fontDescriptor.object(forKey: .featureSettings) as? [[String: Any]] {
                    let features = fontFeatures.compactMap { feature in
                        guard let typeID = feature[FontDescriptor.FeatureKey.cpTypeIdentifier.rawValue] else { return nil }
                        guard let selectorID = feature[FontDescriptor.FeatureKey.selectorIdentifier.rawValue] else { return nil }

                        return "\(typeID)/\(selectorID)"
                        }.sorted(by: <).joined(separator: " ")

                    if features.isEmpty == false {
                        cocoaStyles["-cocoa-font-features"] = features
                    }
                }

                fontStyle += String(format: "%gpx ", fontDescriptor.pointSize)
                fontStyle += "\"\(font.cpFamilyName)\""

                styles["font"] = fontStyle
                cocoaStyles["-cocoa-font-postscriptname"] = "\"\(fontDescriptor.cpPostscriptName)\""
            case .paragraphStyle:
                guard self.ignoreParagraphStyles == false else { return }
                guard let paragraphStyle = value as? NSParagraphStyle else { return }
                guard let alignment = Mappings.TextAlignment.encode[paragraphStyle.alignment] else { return }

                styles["text-align"] = alignment
            case .baselineOffset:
                guard let offset = value as? Float else { return }

                cocoaStyles["-cocoa-baseline-offset"] = String(format: "%.0f", offset)
            case NSAttributedString.Key(rawValue: "NSSuperScript"):
                guard let offset = value as? Int, offset != 0 else { return }

                let verticalAlignment = offset > 0 ? "super" : "sub"
                styles["vertical-align"] = verticalAlignment
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
                break
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
            var cgColor = color.cgColor
            if let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
                if let convertedCGColor = color.cgColor.converted(to: sRGBColorSpace, intent: .defaultIntent, options: nil) {
                    cgColor = convertedCGColor
                }
            }
            red = cgColor.components?[0] ?? 0
            green = cgColor.components?[1] ?? 0
            blue = cgColor.components?[2] ?? 0
        } else {
            (red, green, blue) = (0, 0, 0)
        }

        let r = Int((red * 255.0).rounded())
        let g = Int((green * 255.0).rounded())
        let b = Int((blue * 255.0).rounded())
        return "rgba(\(r), \(g), \(b), \(String(format: "%.6f", alpha)))"
    }
}

// MARK: - String

private extension String {

    var htmlEscaped: String {
        guard self.contains(where: { Character.mapping[$0] != nil }) else { return self }

        return self.reduce("") { $0 + $1.escaped }
    }

    func stringByAppendingAttributeValue(_ value: String?) -> String {
        guard let value = value, value.isEmpty == false else { return self }

        if self.isEmpty {
            return value
        } else {
            return self + " " + value
        }
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
