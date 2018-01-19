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

    typealias AttributeKey = String
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
                let (iteratorAfterEscape, parsedChar)  = self.parseEscape(iterator)
                parsedScalars.append(parsedChar)
                iterator = iteratorAfterEscape
            default:
                parsedScalars.append(character)
            }
        }
        flushContent()
    }
    
    // MARK: - Private
    
    private func parseEscape(_ iterator: String.UnicodeScalarView.Iterator) -> (String.UnicodeScalarView.Iterator, UnicodeScalar) {
        var escapeParseIterator = iterator
        var escapedName = "".unicodeScalars
        
        var parsedCharacters = 0
        while let character = escapeParseIterator.next() {
            if character == ";" {
                switch String(escapedName) {
                case "amp":
                    return (escapeParseIterator, "&")
                case "quot":
                    return (escapeParseIterator, "\"")
                case "apos":
                    return (escapeParseIterator, "'")
                case "lt":
                    return (escapeParseIterator, "<")
                case "gt":
                    return (escapeParseIterator, ">")
                default:
                    return (iterator, "&")
                }
            }
            escapedName.append(character)
            parsedCharacters += 1
            if parsedCharacters > 5 { break }
        }
        return (iterator, "&")
    }
    
    func parseTag(_ iterator: inout String.UnicodeScalarView.Iterator) {
        var potentialTags: Set<Tag> = Set()

        func forwardUntilCloseTag() {
            while let char = iterator.next(), char != ">" {}
        }
        
        switch iterator.next() ?? ">" {
        case "p":
            potentialTags.insert(.p)
        case "s":
            potentialTags.insert(.span)
        case "a":
            potentialTags.insert(.a)
        case ">":
            return
        case "/":
            forwardUntilCloseTag()
            self.delegate?.didCloseTag(self)
            return
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            return
        }
        
        switch iterator.next() ?? ">" {
        case " ":
            if potentialTags.contains(.p) {
                let attributes = self.parseAttributes(&iterator)
                self.delegate?.didOpenTag(self, name: .p, attributes: attributes)
            } else if potentialTags.contains(.a) {
                let attributes = self.parseAttributes(&iterator)
                self.delegate?.didOpenTag(self, name: .a, attributes: attributes)
            } else {
                forwardUntilCloseTag()
                self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            }
            return
        case "p":
            potentialTags.formIntersection([.span])
        case ">":
            if potentialTags.contains(.p) {
                self.delegate?.didOpenTag(self, name: .p, attributes: nil)
            } else if potentialTags.contains(.a) {
                self.delegate?.didOpenTag(self, name: .a, attributes: nil)
            } else {
                self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            }
            return
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            return
        }
        
        switch iterator.next() ?? ">" {
        case " ", ">":
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            return
        case "a":
            potentialTags.formIntersection([.span])
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            return
        }
        
        switch iterator.next() ?? ">" {
        case " ", ">":
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            return
        case "n":
            potentialTags.formIntersection([.span])
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            return
        }
        
        switch iterator.next() ?? ">" {
        case " ":
            if potentialTags.contains(.span) {
                let attributes = self.parseAttributes(&iterator)
                self.delegate?.didOpenTag(self, name: .span, attributes: attributes)
            } else {
                forwardUntilCloseTag()
                self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            }
            return
        case ">":
            if potentialTags.contains(.span) {
                self.delegate?.didOpenTag(self, name: .span, attributes: nil)
            } else {
                self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            }
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(self, name: .ignored, attributes: nil)
            return
        }
    }
    
    func parseAttributes(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedStringKey: Any]? {
        var potentialAttributes: Set<Attribute> = Set()
        var attributes: [NSAttributedStringKey: Any]? = nil

        while let nextChar = iterator.testNextCharacter(), nextChar != ">" {
            iterator.skipStyleAttributeIgnoredCharacters()

            switch iterator.next() ?? ">" {
            case "s":
                potentialAttributes.insert(.style)
            case "h":
                potentialAttributes.insert(.href)
            default:
                return attributes
            }

            switch iterator.next() ?? ">" {
            case "t":
                guard potentialAttributes.contains(.style) else { return attributes }
            case "r":
                guard potentialAttributes.contains(.href) else { return attributes }
            default:
                return attributes
            }

            switch iterator.next() ?? ">" {
            case "y":
                guard potentialAttributes.contains(.style) else { return attributes }
            case "e":
                guard potentialAttributes.contains(.href) else { return attributes }
            default:
                return attributes
            }

            switch iterator.next() ?? ">" {
            case "l":
                guard potentialAttributes.contains(.style) else { return attributes }
            case "f":
                guard potentialAttributes.contains(.href) else { return attributes }

                if attributes != nil {
                    attributes?.merge(self.parseHRef(&iterator)) { return $1 }
                } else {
                    attributes = self.parseHRef(&iterator)
                }
            default:
                return attributes
            }

            switch iterator.next() ?? ">" {
            case "e":
                guard potentialAttributes.contains(.style) else { return attributes }

                if attributes != nil {
                    attributes?.merge(self.parseStyles(&iterator)) { return $1 }
                } else {
                    attributes = self.parseStyles(&iterator)
                }
            default:
                return attributes
            }
            iterator.skipStyleAttributeIgnoredCharacters()
        }
        return attributes
    }
    
    func parseStyles(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedStringKey: Any] {
        var attributes: [NSAttributedStringKey: Any] = [:]

        iterator.skipStyleAttributeIgnoredCharacters()
        _ = iterator.next() // skip first "\'"

        while let firstChar = iterator.testNextCharacter(), firstChar != "'", firstChar != ">" {
            switch firstChar {
            case "b":
                if iterator.forwardIfEquals(AttributeKeys.Style.backgroundColor) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    attributes[.backgroundColor] = iterator.parseColor()
                } else {
                    iterator.foward(until: ";")
                }
            case "c":
                if iterator.forwardIfEquals(AttributeKeys.Style.color) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    attributes[.foregroundColor] = iterator.parseColor()
                } else {
                    iterator.foward(until: ";")
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
                } else {
                    iterator.foward(until: ";")
                }
            case "f":
                if iterator.forwardIfEquals(AttributeKeys.Style.font) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    attributes[.font] = iterator.scanString(until: ";")
                } else {
                    iterator.foward(until: ";")
                }
            case "v":
                if iterator.forwardIfEquals(AttributeKeys.Style.verticalAlign) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    attributes[.superscript] = iterator.scanString(until: ";")
                } else {
                    iterator.foward(until: ";")
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
                        } else {
                            iterator.foward(until: ";")
                        }
                    case "u":
                        if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.underlineColor) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            attributes[.underlineColor] = iterator.parseColor()
                        } else if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.underline) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            attributes[.underlineStyle] = iterator.parseUnderlineStyle()
                        } else {
                            iterator.foward(until: ";")
                        }
                    case "b":
                        if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.baseOffset) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            attributes[.baselineOffset] = iterator.scanString(until: ";")
                        } else {
                            iterator.foward(until: ";")
                        }
                    case "v":
                        if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.verticalAlign) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            attributes[.superscript] = iterator.scanString(until: ";")
                        } else {
                            iterator.foward(until: ";")
                        }
                    case "f":
                        if iterator.forwardIfEquals(AttributeKeys.Style.Cocoa.fontPostScriptName) {
                            iterator.skipStyleAttributeIgnoredCharacters()
                            attributes[.font] = iterator.scanString(until: ";")
                        } else {
                            iterator.foward(until: ";")
                        }
                    default:
                        iterator.foward(until: ";")
                    }
                }
            default:
                iterator.foward(until: ";")
            }
            iterator.skipStyleAttributeIgnoredCharacters()
        }
        _ = iterator.next() // skip last '
        return attributes
    }
    
    func parseHRef(_ iterator: inout String.UnicodeScalarView.Iterator) -> [NSAttributedStringKey: Any] {
        var href = "".unicodeScalars
        iterator.skipStyleAttributeIgnoredCharacters()
        _ = iterator.next() // skip first "\'"

        while let char = iterator.next(), char != "'" {
            href.append(char)
        }
        guard let url = URL(string: String(href)) else { return [:] }

        return [.link: url]
    }
}
