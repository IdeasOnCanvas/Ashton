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
}


final class AshtonXMLParser {
    
    private static let closeChar: UnicodeScalar = ">"
    private static let openChar: UnicodeScalar = "<"
    private static let slash: UnicodeScalar = "/"
    private static let escapeStart: UnicodeScalar = "&"
    
    private let xmlString: String
    private var tags: [Int] = []
    private var snippets: [String] = []
    
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
        var tag: String = ""
        if let character = iterator.next() {
            if character == AshtonXMLParser.slash {
                while let char = iterator.next(), char != AshtonXMLParser.closeChar { }
                self.tags.removeLast()
                return
            } else {
               // tag.unicodeScalars.append(character)
            }
        }
        var tag2 = 0
        var appender = 0
        while let character = iterator.next(), character != AshtonXMLParser.closeChar {
            switch character {
            case "p":
                tag2 = 1
            case "s":
                tag2 = 2
            default:
                tag2 = 3
            }
            if character == "p" {
                
            }
            appender += 1
            tag.unicodeScalars.append(character)
            if appender % 2 == 0 {
               // self.snippets.append(tag)
                tag = ""
            }
            
        }
        self.tags.append(tag2)
    }
    
    static let p = "p"
    static let span = "span"
    
//    func matcher(iterator: inout String.UnicodeScalarView.Iterator) {
//        var potentialMatches = [AshtonXMLParser.p.makeIterator(), AshtonXMLParser.span.makeIterator()]
//        var index = 0
//        while let character = iterator.next(), potentialMatches.count > 0 {
//            index += 1
//            for testitem in potentialMatches {
//                p.mak.next()
//            }
//        }
//    }
}
