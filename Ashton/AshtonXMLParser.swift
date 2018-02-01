//
//  XMLParser.swift
//  Ashton
//
//  Created by Michael Schwarz on 15.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

import Foundation
#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif


protocol AshtonXMLParserDelegate: class {
    func didParseContent(_ parser: AshtonXMLParser, string: String)
    func didOpenTag(_ parser: AshtonXMLParser, name: AshtonXMLParser.Tag, attributes: [NSAttributedStringKey: Any]?)
    func didCloseTag(_ parser: AshtonXMLParser)
}


/// Parses Ashton XML and returns parsed content and attributes
final class AshtonXMLParser {
    
    enum Tag {
        case p
        case span
        case a
        case ignored
    }

    struct AttributeKeys {

        struct Style {
            static let backgroundColor = "background-color"
            static let color = "color"
            static let textDecoration = "text-decoration"
            static let font = "font"
            static let textAlign = "text-align"
            static let verticalAlign = "vertical-align"

            struct Cocoa {
                static let commonPrefix = "-cocoa-"
                static let strikethroughColor = "strikethrough-color"
                static let underlineColor = "underline-color"
                static let baseOffset = "baseline-offset"
                static let verticalAlign = "vertical-align"
                static let fontPostScriptName = "font-postscriptname"
                static let underline = "underline"
                static let strikethrough = "strikethrough"
                static let fontFeatures = "font-features"
            }
        }
    }

    static var styleAttributesCache: [UInt64: [NSAttributedStringKey: Any]] = [:]
    
    // MARK: - AshtonXMLParser
    
    weak var delegate: AshtonXMLParserDelegate?
    
    func parse(string: String) {
        var parsedScalars = "".unicodeScalars
        var iterator: String.UnicodeScalarView.Iterator = string.unicodeScalars.makeIterator()
        
        func flushContent() {
            guard parsedScalars.isEmpty == false else { return }
            
            delegate?.didParseContent(self, string: String(parsedScalars))
            parsedScalars = "".unicodeScalars
        }
        
        while let character = iterator.next() {
            switch character {
            case "<":
                flushContent()
                self.parseTag(&iterator)
            case "&":
                if let escapedChar = iterator.parseEscapedChar() {
                    parsedScalars.append(escapedChar)
                } else {
                    parsedScalars.append(character)
                }
            default:
                parsedScalars.append(character)
            }
        }
        flushContent()
    }
}


// MARK: - Private

private extension AshtonXMLParser {

    // MARK: - Tag Parsing
    
    func parseTag(_ iterator: inout String.UnicodeScalarView.Iterator) {
        guard let nextCharacter = iterator.next(), nextCharacter != ">" else { return }
        
        switch nextCharacter {
        case "b":
            if iterator.forwardIfEquals("r /") {
                iterator.foward(untilAfter: ">")
                self.delegate?.didParseContent(self, string: "\n")
            } else {
                self.finalizeOpening(of: .ignored, iterator: &iterator)
            }
        case "p":
            self.finalizeOpening(of: .p, iterator: &iterator)
        case "s":
            let parsedTag: Tag = iterator.forwardIfEquals("pan") ? .span : .ignored
            self.finalizeOpening(of: parsedTag, iterator: &iterator)
        case "a":
            self.finalizeOpening(of: .a, iterator: &iterator)
        case "/":
            iterator.foward(untilAfter: ">")
            self.delegate?.didCloseTag(self)
        default:
            self.finalizeOpening(of: .ignored, iterator: &iterator)
        }
    }

    func finalizeOpening(of tag: Tag, iterator: inout String.UnicodeScalarView.Iterator) {
        guard tag != .ignored else {
            iterator.foward(untilAfter: ">")
            self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            return
        }
        guard let nextChar = iterator.next() else { return }

        switch nextChar {
        case ">":
            self.delegate?.didOpenTag(self, name: tag, attributes: nil)
        case " ":
            let attributes = self.parseAttributes(&iterator)
            self.delegate?.didOpenTag(self, name: tag, attributes: attributes)
        default:
             iterator.foward(untilAfter: ">")
            // it seems we parsed only a prefix and the actual tag is unknown
            self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
        }
    }

    // MARK: - Attribute Parsing
    
    func parseAttributes(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedStringKey: Any]? {
        var parsedAttributes: [NSAttributedStringKey: Any]? = nil

        func addAttributes(_ attributes: [NSAttributedStringKey: Any]) {
            if parsedAttributes == nil {
                parsedAttributes = attributes
            } else {
                parsedAttributes?.merge(attributes) { return $1 }
            }
        }

        while let nextChar = iterator.next(), nextChar != ">" {
            switch nextChar {
            case "s":
                guard iterator.forwardAndCheckingIfEquals("tyle") else { break }

                iterator.foward(untilAfter: "=")
                addAttributes(self.parseStyles(&iterator))
            case "h":
                guard iterator.forwardAndCheckingIfEquals("ref") else { break }

                iterator.foward(untilAfter: "=")
                addAttributes(self.parseHRef(&iterator))
            default:
                break
            }
        }
        return parsedAttributes
    }

    // MARK: - Style Parsing
    
    func parseStyles(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedStringKey: Any] {
        var fontBuilder: FontBuilder?
        var attributes: [NSAttributedStringKey: Any] = [:]

        iterator.foward(untilAfter: "'")

        let cacheKey = iterator.hash(until: "'")
        if let cachedAttributes = AshtonXMLParser.styleAttributesCache[cacheKey] {
            while let char = iterator.next(), char != "'", char != ">" {}

            return cachedAttributes
        }

        while let char = iterator.testNextCharacter(), char != "'", char != ">" {
            switch char {
            case "b":
                guard iterator.forwardIfEquals(AttributeKeys.Style.backgroundColor) else { break }

                iterator.skipStyleAttributeIgnoredCharacters()
                attributes[.backgroundColor] = iterator.parseColor()
            case "c":
                guard iterator.forwardIfEquals(AttributeKeys.Style.color) else { break }

                iterator.skipStyleAttributeIgnoredCharacters()
                attributes[.foregroundColor] = iterator.parseColor()
            case "t":
                if iterator.forwardIfEquals(AttributeKeys.Style.textAlign) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    guard let textAlignment = iterator.parseTextAlignment() else { break }

                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = textAlignment
                    attributes[.paragraphStyle] = paragraphStyle
                } else if iterator.forwardIfEquals(AttributeKeys.Style.textDecoration) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    guard let textDecoration = iterator.parseTextDecoration() else { break }

                    attributes[textDecoration] = NSUnderlineStyle.styleSingle.rawValue
                }
            case "f":
                guard iterator.forwardIfEquals(AttributeKeys.Style.font) else { break }

                iterator.skipStyleAttributeIgnoredCharacters()

                let fontAttributes = iterator.parseFontAttributes()
                fontBuilder = fontBuilder ?? FontBuilder()
                fontBuilder?.isBold = fontAttributes.isBold
                fontBuilder?.isItalic = fontAttributes.isItalic
                fontBuilder?.familyName = fontAttributes.family
                fontBuilder?.pointSize = fontAttributes.points
            case "v":
                guard iterator.forwardIfEquals(AttributeKeys.Style.verticalAlign) else { break }

                iterator.skipStyleAttributeIgnoredCharacters()
                guard attributes[.superscript] == nil else { break }
                guard let alignment = iterator.parseVerticalAlignmentFromString() else { break }
                    
                attributes[.superscript] = alignment
            case "-":
                guard iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.commonPrefix) else { break }
                guard let firstChar = iterator.testNextCharacter() else { break }

                switch firstChar {
                case "s":
                    if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.strikethroughColor) {
                        iterator.skipStyleAttributeIgnoredCharacters()
                        attributes[.strikethroughColor] = iterator.parseColor()
                    } else if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.strikethrough) {
                        iterator.skipStyleAttributeIgnoredCharacters()
                        guard let underlineStyle = iterator.parseUnderlineStyle() else { break }

                        attributes[.strikethroughStyle] = underlineStyle.rawValue
                    }
                case "u":
                    if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.underlineColor) {
                        iterator.skipStyleAttributeIgnoredCharacters()
                        attributes[.underlineColor] = iterator.parseColor()
                    } else if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.underline) {
                        iterator.skipStyleAttributeIgnoredCharacters()
                        guard let underlineStyle = iterator.parseUnderlineStyle() else { break }

                        attributes[.underlineStyle] = underlineStyle.rawValue
                    }
                case "b":
                    guard iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.baseOffset) else { break }
                    iterator.skipStyleAttributeIgnoredCharacters()
                    guard let baselineOffset = iterator.parseBaselineOffset() else { break }

                    attributes[.baselineOffset] = baselineOffset
                case "v":
                    guard iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.verticalAlign) else { break }
                    
                    iterator.skipStyleAttributeIgnoredCharacters()
                    guard let verticalAlignment = iterator.parseVerticalAlignment() else { break }

                    attributes[.superscript] = verticalAlignment
                case "f":
                    if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.fontPostScriptName) {
                        iterator.skipStyleAttributeIgnoredCharacters()
                        guard let postscriptName = iterator.parsePostscriptFontName() else { break }

                        fontBuilder = fontBuilder ?? FontBuilder()
                        fontBuilder?.postScriptName = postscriptName
                    } else if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.fontFeatures) {
                        iterator.skipStyleAttributeIgnoredCharacters()
                        let fontFeatures = iterator.parseFontFeatures()
                        guard fontFeatures.isEmpty == false else { break }

                        fontBuilder = fontBuilder ?? FontBuilder()
                        fontBuilder?.fontFeatures = fontFeatures
                    }
                default:
                    break
                }
            default:
                break
            }
            iterator.foward(untilAfter: ";")
            iterator.skipStyleAttributeIgnoredCharacters()
        }

        iterator.foward(untilAfter: "'")
        if let font = fontBuilder?.makeFont() {
            attributes[.font] = font
        }
        
        AshtonXMLParser.styleAttributesCache[cacheKey] = attributes
        return attributes
    }

    // MARK: HRef Parsing
    
    func parseHRef(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedStringKey: Any] {
        iterator.skipStyleAttributeIgnoredCharacters()
        guard let url = iterator.parseURL() else { return [:] }
        
        return [.link: url]
    }
}
