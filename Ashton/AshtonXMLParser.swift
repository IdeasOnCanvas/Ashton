//
//  XMLParser.swift
//  Ashton
//
//  Created by Michael Schwarz on 15.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

import Foundation


protocol AshtonXMLParserDelegate: class {
    func didParseContent(_ string: String)
    func didOpenTag(_ tag: AshtonXMLParser.Tag, attributes: [AshtonXMLParser.Attribute: [AshtonXMLParser.AttributeKey: String]]?)
    func didCloseTag()
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

    enum AttributeKey: String {
        case backgroundColor = "background-color"
        /*
         case "background-color":
         case "color":
         case "text-decoration":
         case "font":
         case "text-align":
         case "vertical-align":
         case "-cocoa-strikethrough-color":
         case "-cocoa-underline-color":
         case "-cocoa-baseline-offset":
         case "-cocoa-vertical-align":
         case "-cocoa-font-postscriptname":
         case "-cocoa-underline":
         case "-cocoa-strikethrough":
 */
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
            
            delegate?.didParseContent(String(parsedScalars))
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
            self.delegate?.didCloseTag()
            return
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(.ignored, attributes: nil)
            return
        }
        
        switch iterator.next() ?? ">" {
        case " ":
            if potentialTags.contains(.p) {
                let attributes = self.parseAttributes(&iterator)
                self.delegate?.didOpenTag(.p, attributes: attributes)
            } else if potentialTags.contains(.a) {
                let attributes = self.parseAttributes(&iterator)
                self.delegate?.didOpenTag(.a, attributes: attributes)
            } else {
                forwardUntilCloseTag()
                self.delegate?.didOpenTag(.ignored, attributes: nil)
            }
            return
        case "p":
            potentialTags.formIntersection([.span])
        case ">":
            if potentialTags.contains(.p) {
                self.delegate?.didOpenTag(.p, attributes: nil)
            } else if potentialTags.contains(.a) {
                self.delegate?.didOpenTag(.a, attributes: nil)
            } else {
                self.delegate?.didOpenTag(.ignored, attributes: nil)
            }
            return
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(.ignored, attributes: nil)
            return
        }
        
        switch iterator.next() ?? ">" {
        case " ", ">":
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(.ignored, attributes: nil)
            return
        case "a":
            potentialTags.formIntersection([.span])
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(.ignored, attributes: nil)
            return
        }
        
        switch iterator.next() ?? ">" {
        case " ", ">":
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(.ignored, attributes: nil)
            return
        case "n":
            potentialTags.formIntersection([.span])
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(.ignored, attributes: nil)
            return
        }
        
        switch iterator.next() ?? ">" {
        case " ":
            if potentialTags.contains(.span) {
                let attributes = self.parseAttributes(&iterator)
                self.delegate?.didOpenTag(.span, attributes: attributes)
            } else {
                forwardUntilCloseTag()
                self.delegate?.didOpenTag(.ignored, attributes: nil)
            }
            return
        case ">":
            if potentialTags.contains(.span) {
                self.delegate?.didOpenTag(.span, attributes: nil)
            } else {
                self.delegate?.didOpenTag(.ignored, attributes: nil)
            }
        default:
            forwardUntilCloseTag()
            self.delegate?.didOpenTag(.ignored, attributes: nil)
            return
        }
    }
    
    func parseAttributes(_ iterator: inout String.UnicodeScalarView.Iterator) -> [Attribute: [AshtonXMLParser.AttributeKey: String]]? {
        var potentialAttributes: Set<Attribute> = Set()
        
        switch iterator.next() ?? ">" {
        case "s":
            potentialAttributes.insert(.style)
        case "h":
            potentialAttributes.insert(.href)
        default:
            return nil
        }
        
        switch iterator.next() ?? ">" {
        case "t":
            guard potentialAttributes.contains(.style) else { return nil }
        case "r":
            guard potentialAttributes.contains(.href) else { return nil }
        default:
            return nil
        }
        
        switch iterator.next() ?? ">" {
        case "y":
            guard potentialAttributes.contains(.style) else { return nil }
        case "e":
            guard potentialAttributes.contains(.href) else { return nil }
        default:
            return nil
        }
        
        switch iterator.next() ?? ">" {
        case "l":
            guard potentialAttributes.contains(.style) else { return nil }
        case "f":
            guard potentialAttributes.contains(.href) else { return nil }
            
            return [.href: self.parseHRef(&iterator)]
        default:
            return nil
        }
        
        switch iterator.next() ?? ">" {
        case "e":
            guard potentialAttributes.contains(.style) else { return nil }
            
            return [.style: self.parseStyles(&iterator)]
        default:
            return nil
        }
    }
    
    func parseStyles(_ iterator: inout String.UnicodeScalarView.Iterator) -> [AttributeKey: String] {
        var attributes: [AttributeKey: String] = [:]

        while let char = iterator.next(), char != ">" {
            iterator.skipStyleAttributeIgnoredCharacters()

            guard let firstChar = iterator.testNextCharacter() else { break }
            switch firstChar {
            case "b":
                if iterator.forwardIfEquals(AttributeKey.backgroundColor.rawValue) {
                    iterator.skipStyleAttributeIgnoredCharacters()
                    attributes[.backgroundColor] = iterator.scanString(until: ";")
                }
            case "c":
                iterator.forwardIfEquals("olor")
            case "t":
                iterator.forwardIfEquals("ext-decoration")
            case "f":
                iterator.forwardIfEquals("ont")
            case "v":
                iterator.forwardIfEquals("ertical-align")
            case "-":
                iterator.forwardIfEquals("-coco")
            default:
                break;
            }
        }
        return attributes
    }
    
    func parseHRef(_ iterator: inout String.UnicodeScalarView.Iterator) -> [AttributeKey: String] {
        var href = "".unicodeScalars
        
//        while let char = iterator.next(), char != ">" {
//           href.append(char)
//        }
        return [:]
    }
}

// MARK: - Private

private extension String.UnicodeScalarView.Iterator {

    @discardableResult
    mutating func forwardIfEquals(_ string: String) -> Bool {
        var testingIterator = self
        var referenceIterator = string.unicodeScalars.makeIterator()
        while let referenceChar = referenceIterator.next() {
            guard referenceChar == testingIterator.next() else {
                return false
            }
        }
        self = testingIterator
        return true
    }

    mutating func scanString(until stopChar: Unicode.Scalar) -> String {
        var scannedScalars = "".unicodeScalars
        var scanningIterator = self

        while let char = scanningIterator.next(), char != stopChar {
            self = scanningIterator
            scannedScalars.append(char)
        }
        return String(scannedScalars)
    }

    mutating func skipStyleAttributeIgnoredCharacters() {
        let testingSet = Set<Unicode.Scalar>(["=", " ", ";", "\'", ":"])
        var testingIterator = self
        while let referenceChar = testingIterator.next(), testingSet.contains(referenceChar) { self = testingIterator}
    }

    func testNextCharacter() -> Unicode.Scalar? {
        var copiedIterator = self
        return copiedIterator.next()
    }
}
