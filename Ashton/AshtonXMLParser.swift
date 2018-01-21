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

extension NSAttributedStringKey {
    static let superscript = NSAttributedStringKey(rawValue: "NSSuperScript")
}


final class AshtonXMLParser {
    
    enum Attribute {
        case style
        case href
    }
    
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
            }
        }
    }
    
    private static let closeChar: UnicodeScalar = ">"
    private static let openChar: UnicodeScalar = "<"
    private static let escapeStart: UnicodeScalar = "&"
    
    private let xmlString: String
    
    // MARK: - Lifecycle
    
    weak var delegate: AshtonXMLParserDelegate?
    
    init(xmlString: String) {
        self.xmlString = xmlString
    }
    
    func parse() {
        var parsedScalars = "".unicodeScalars
        var iterator: String.UnicodeScalarView.Iterator = self.xmlString.unicodeScalars.makeIterator()
        
        func flushContent() {
            guard parsedScalars.isEmpty == false else { return }
            
            delegate?.didParseContent(self, string: String(parsedScalars))
            parsedScalars = "".unicodeScalars
        }
        
        while let character = iterator.next() {
            switch character {
            case AshtonXMLParser.openChar:
                flushContent()
                self.parseTag(&iterator)
            case AshtonXMLParser.escapeStart:
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
    
    // MARK: - Private
    
    func parseTag(_ iterator: inout String.UnicodeScalarView.Iterator) {

        func forwardUntilCloseTag() {
            while let char = iterator.next(), char != ">" {}
        }
        
        switch iterator.next() ?? ">" {
        case "b":
            guard iterator.forwardIfEquals("r /") else {
                forwardUntilCloseTag()
                self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
                return
            }
            self.delegate?.didParseContent(self, string: "\n")
        case "p":
            guard let nextChar = iterator.next() else { return }
            
            if nextChar == ">" {
                self.delegate?.didOpenTag(self, name: .p, attributes: nil)
            } else if nextChar == " " {
                let attributes = self.parseAttributes(&iterator)
                self.delegate?.didOpenTag(self, name: .p, attributes: attributes)
            } else {
                forwardUntilCloseTag()
                self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            }
        case "s":
            guard iterator.forwardIfEquals("pan") else {
                forwardUntilCloseTag()
                self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
                return
            }
            
            guard let nextChar = iterator.next() else { return }
            
            if nextChar == ">" {
                self.delegate?.didOpenTag(self, name: .span, attributes: nil)
            } else if nextChar == " " {
                let attributes = self.parseAttributes(&iterator)
                self.delegate?.didOpenTag(self, name: .span, attributes: attributes)
            } else {
                forwardUntilCloseTag()
                self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            }
        case "a":
            guard let nextChar = iterator.next() else { return }
            
            if nextChar == ">" {
                self.delegate?.didOpenTag(self, name: .a, attributes: nil)
            } else if nextChar == " " {
                let attributes = self.parseAttributes(&iterator)
                self.delegate?.didOpenTag(self, name: .a, attributes: attributes)
            } else {
                forwardUntilCloseTag()
                self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            }
        case ">":
            return
        case "/":
            forwardUntilCloseTag()
            self.delegate?.didCloseTag(self)
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
        }
    }
    
    func parseAttributes(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedStringKey: Any]? {
        var attributes: [NSAttributedStringKey: Any]? = nil
        
        iterator.skipStyleAttributeIgnoredCharacters()
        while let firstChar = iterator.next(), firstChar != ">" {
            
            switch firstChar {
            case "s":
                guard iterator.forwardIfEquals("tyle") else { break }
                
                if attributes != nil {
                    attributes?.merge(self.parseStyles(&iterator)) { return $1 }
                } else {
                    attributes = self.parseStyles(&iterator)
                }
            case "h":
                guard iterator.forwardIfEquals("ref") else { break }
                
                if attributes != nil {
                    attributes?.merge(self.parseHRef(&iterator)) { return $1 }
                } else {
                    attributes = self.parseHRef(&iterator)
                }
            default:
                break
            }
            iterator.skipStyleAttributeIgnoredCharacters()
        }
        return attributes
    }
    
    func parseStyles(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedStringKey: Any] {
        var fontBuilder: FontBuilder?
        var attributes: [NSAttributedStringKey: Any] = [:]

        iterator.skipStyleAttributeIgnoredCharacters()
        _ = iterator.next() // skip first "\'"

        while let firstChar = iterator.testNextCharacter(), firstChar != "'", firstChar != ">" {
            switch firstChar {
            case "b":
                if iterator.forwardIfEquals(AttributeKeys.Style.backgroundColor) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    attributes[.backgroundColor] = iterator.parseColor()
                }
            case "c":
                if iterator.forwardIfEquals(AttributeKeys.Style.color) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    attributes[.foregroundColor] = iterator.parseColor()
                }
            case "t":
                if iterator.forwardIfEquals(AttributeKeys.Style.textAlign) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    guard let textAlignment =  iterator.parseTextAlignment() else { break }

                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = textAlignment
                    attributes[.paragraphStyle] = paragraphStyle
                } else if iterator.forwardIfEquals(AttributeKeys.Style.textDecoration) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    guard let textDecoration = iterator.parseTextDecoration() else { break }

                    attributes[textDecoration] = NSUnderlineStyle.styleSingle.rawValue
                }
            case "f":
                if iterator.forwardIfEquals(AttributeKeys.Style.font) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    
                    let fontAttributes = iterator.parseFontAttributes()
                    
                    fontBuilder = fontBuilder ?? FontBuilder()
                    fontBuilder?.isBold = fontAttributes.isBold
                    fontBuilder?.isItalic = fontAttributes.isItalic
                    fontBuilder?.familyName = fontAttributes.family
                    fontBuilder?.pointSize = fontAttributes.points
                }
            case "v":
                if iterator.forwardIfEquals(AttributeKeys.Style.verticalAlign) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    guard attributes[.superscript] == nil else { break }
                    guard let alignment = iterator.parseVerticalAlignmentFromString() else { break }
                    
                    attributes[.superscript] = alignment
                }
            case "-":
                if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.commonPrefix) {
                    guard let firstChar = iterator.testNextCharacter() else { break }

                    switch firstChar {
                    case "s":
                        if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.strikethroughColor) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            attributes[.strikethroughColor] = iterator.parseColor()
                        } else if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.strikethrough) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            attributes[.underlineStyle] = iterator.parseUnderlineStyle()
                        }
                    case "u":
                        if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.underlineColor) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            attributes[.underlineColor] = iterator.parseColor()
                        } else if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.underline) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            attributes[.underlineStyle] = iterator.parseUnderlineStyle()
                        }
                    case "b":
                        if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.baseOffset) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            guard let baselineOffset = iterator.parseBaselineOffset() else { break }
                            
                            attributes[.baselineOffset] = baselineOffset
                        }
                    case "v":
                        if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.verticalAlign) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            guard let verticalAlignment = iterator.parseVerticalAlignment() else { break }
                            
                            attributes[.superscript] = verticalAlignment
                        }
                    case "f":
                        if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.fontPostScriptName) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            guard let postscriptName = iterator.parsePostscriptFontName() else { break }
                            
                            fontBuilder?.postScriptName = postscriptName
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
            iterator.foward(until: ";")
            iterator.skipStyleAttributeIgnoredCharacters()
        }
        _ = iterator.next() // skip last '
        if let font = fontBuilder?.makeFont() {
            attributes[.font] = font
        }
        return attributes
    }
    
    func parseHRef(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedStringKey: Any] {
        iterator.skipStyleAttributeIgnoredCharacters()
        guard let url = iterator.parseURL() else { return [:] }
        
        return [.link: url]
    }
}
