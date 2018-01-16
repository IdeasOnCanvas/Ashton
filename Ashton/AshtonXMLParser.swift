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
    func didOpenTag(_ tag: AshtonXMLParser.Tag, attributes: String?)
    func didCloseTag()
}


final class AshtonXMLParser {
    
    enum Tag {
        case p
        case span
        case a
        case ignored
        
        static var allTags: Set<Tag> {
            return Set([.p, .span])
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
    
    func parseAttributes(_ iterator: inout String.UnicodeScalarView.Iterator) -> String {
        var attributes = "".unicodeScalars
        while let char = iterator.next(), char != ">" {
            attributes.append(char)
        }
        return String(attributes)
    }
}
