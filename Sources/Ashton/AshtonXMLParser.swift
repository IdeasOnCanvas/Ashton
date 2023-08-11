//
//  XMLParser.swift
//  Ashton
//
//  Created by Michael Schwarz on 15.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

import Foundation
#if os(iOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif


protocol AshtonXMLParserDelegate: AnyObject {
    func didParseContent(_ parser: AshtonXMLParser, string: String)
    func didOpenTag(_ parser: AshtonXMLParser, name: AshtonXMLParser.Tag, attributes: [NSAttributedString.Key: Any]?)
    func didCloseTag(_ parser: AshtonXMLParser)
    func didEncounterUnknownFont(_ parser: AshtonXMLParser, fontName: String)
}

extension AshtonXMLParserDelegate {

    func didEncounterUnknownFont(_ parser: AshtonXMLParser, fontName: String) { }
}


/// Parses Ashton XML and returns parsed content and attributes
final class AshtonXMLParser {

    typealias Hash = Int
    typealias StyleAttributesCache = Cache<Hash, [NSAttributedString.Key: Any]>
    
    enum Tag {
        case p
        case span
        case strong
        case em
        case a
        case ignored
    }

    enum AttributeKeys {

        enum Style {
            static let backgroundColor = "background-color"
            static let color = "color"
            static let textDecoration = "text-decoration"
            static let font = "font"
            static let textAlign = "text-align"
            static let verticalAlign = "vertical-align"

            enum Cocoa {
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

    // MARK: - Properties

    private(set) var fontBuilderCache: FontBuilder.FontCache
    private(set) var styleAttributesCache: StyleAttributesCache

    // MARK: - Lifecycle

    init(styleAttributesCache: StyleAttributesCache? = nil, fontBuilderCache: FontBuilder.FontCache? = nil) {
        self.styleAttributesCache = styleAttributesCache ?? .init()
        self.fontBuilderCache = fontBuilderCache ?? .init()
    }

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

    func clearStyleAttributesCache() {
        self.styleAttributesCache = .init()
    }

    func updateFontBuilderCache(_ cache: FontBuilder.FontCache) {
        self.fontBuilderCache = cache
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
            let parsedTag: Tag
            if iterator.forwardIfEquals("pan") {
                parsedTag = .span
            } else if iterator.forwardIfEquals("trong") {
                parsedTag = .strong
            } else {
                parsedTag = .ignored
            }
            self.finalizeOpening(of: parsedTag, iterator: &iterator)
        case "e":
            let parsedTag: Tag = iterator.forwardIfEquals("m") ? .em : .ignored
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
    
    func parseAttributes(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedString.Key: Any]? {
        var parsedAttributes: [NSAttributedString.Key: Any]? = nil

        func addAttributes(_ attributes: [NSAttributedString.Key: Any]) {
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
                addAttributes(self.parseHREF(&iterator))
            default:
                break
            }
        }
        return parsedAttributes
    }

    // MARK: - Style Parsing
    
    func parseStyles(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]

        var fontBuilder: FontBuilder?
        func ensureFontBuilder() -> FontBuilder {
            if let fontBuilder = fontBuilder {
                return fontBuilder
            }
            let newFontBuilder = FontBuilder(fontCache: self.fontBuilderCache)
            fontBuilder = newFontBuilder
            return newFontBuilder
        }

        iterator.skipWhiteSpace()
        guard let terminationCharacter = iterator.next(), terminationCharacter == "'" || terminationCharacter == "\"" else { return attributes }

        let cacheKey = iterator.hash(until: terminationCharacter)
        if let cachedAttributes = self.styleAttributesCache[cacheKey] {
            iterator.foward(untilAfter: terminationCharacter)

            return cachedAttributes
        }

        while let char = iterator.testNextCharacter(), char != terminationCharacter, char != ">" {
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
                    // we have to use a temporary iterator to ensure that we are not skipping attributes too far
                    var tempIterator = iterator
                    while let textDecoration = tempIterator.parseTextDecoration() {
                        attributes[textDecoration] = NSUnderlineStyle.single.rawValue
                        iterator = tempIterator
                        tempIterator.skipStyleAttributeIgnoredCharacters()
                    }
                }
            case "f":
                guard iterator.forwardIfEquals(AttributeKeys.Style.font) else { break }

                iterator.skipStyleAttributeIgnoredCharacters()

                let fontAttributes = iterator.parseFontAttributes()
                let fontBuilder = ensureFontBuilder()
                fontBuilder.isBold = fontAttributes.isBold
                fontBuilder.isItalic = fontAttributes.isItalic
                fontBuilder.familyName = fontAttributes.family
                fontBuilder.pointSize = fontAttributes.points
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

                        let fontBuilder = ensureFontBuilder()
                        fontBuilder.postScriptName = postscriptName
                    } else if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.fontFeatures) {
                        iterator.skipStyleAttributeIgnoredCharacters()
                        let fontFeatures = iterator.parseFontFeatures()
                        guard fontFeatures.isEmpty == false else { break }

                        let fontBuilder = ensureFontBuilder()
                        fontBuilder.fontFeatures = fontFeatures
                    }
                default:
                    break
                }
            default:
                break
            }
            guard iterator.forwardUntilNextAttribute(terminationChar: terminationCharacter) else { break }
        }

        iterator.foward(untilAfter: terminationCharacter)

        if let font = fontBuilder?.makeFont() {
            attributes[.font] = font
            // Core Text implicitly returns a fallback font if the the requested font descriptor
            // does not lead to an exact match. We perform a simple heuristic to take note of such
            // fallbacks and inform the delegate.
            if let requestedFontName = fontBuilder?.fontName, font.fontName != requestedFontName {
                self.delegate?.didEncounterUnknownFont(self, fontName: requestedFontName)
            }
        }
        
        self.styleAttributesCache[cacheKey] = attributes
        return attributes
    }

    // MARK: - href-Parsing
    
    func parseHREF(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedString.Key: Any] {
        iterator.skipStyleAttributeIgnoredCharacters()
        guard let url = iterator.parseURL() else { return [:] }
        
        return [.link: url]
    }
}
