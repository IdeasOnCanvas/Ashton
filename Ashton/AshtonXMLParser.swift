//
//  XMLParser.swift
//  Ashton
//
//  Created by Michael Schwarz on 15.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

import Foundation


final class AshtonXMLParser {
    
    private static let closeChar: UnicodeScalar = ">"
    private static let openChar: UnicodeScalar = "<"
    private static let slash: UnicodeScalar = "/"
    private static let escapeStart: UnicodeScalar = "&"
    
    private let xmlString: String
    private var tags: [Int] = []
    private var snippets: [String] = []
    private var outputString: String = ""
    
    // MARK: - Lifecycle
    
    init(xmlString: String) {
        self.xmlString = xmlString
    }
    
    func parse() -> String {
        self.outputString = ""
        var iterator: String.UnicodeScalarView.Iterator = self.xmlString.unicodeScalars.makeIterator()
        
        while let character = iterator.next() {
            switch character {
            case AshtonXMLParser.openChar:
                self.parseTag(&iterator)
            case AshtonXMLParser.escapeStart:
                iterator = self.parseEscape(iterator)
            default:
                self.outputString.unicodeScalars.append(character)
            }
        }
        return self.outputString
    }
    
    // MARK: - Private
    
    private func parseEscape(_ iterator: String.UnicodeScalarView.Iterator) -> String.UnicodeScalarView.Iterator {
        var escapeParseIterator = iterator
        var escapedName = "".unicodeScalars
        
        var parsedCharacters = 0
        while let character = escapeParseIterator.next() {
            if character == ";" {
                switch String(escapedName) {
                case "amp":
                    self.outputString.unicodeScalars.append("&")
                case "quot":
                    self.outputString.unicodeScalars.append("\"")
                case "apos":
                    self.outputString.unicodeScalars.append("'")
                case "lt":
                    self.outputString.unicodeScalars.append("<")
                case "gt":
                    self.outputString.unicodeScalars.append(">")
                default:
                    self.outputString.unicodeScalars.append("&")
                    return iterator
                }
                return escapeParseIterator
            }
            escapedName.append(character)
            parsedCharacters += 1
            if parsedCharacters > 5 { break }
        }
        self.outputString.unicodeScalars.append("&")
        return iterator
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
