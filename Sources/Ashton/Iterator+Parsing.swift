//
//  Iterator+Parsing.swift
//  Ashton
//
//  Created by Michael Schwarz on 19.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

import Foundation
#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif


/// Parsing helpers
extension String.UnicodeScalarView.Iterator {

    @discardableResult
    mutating func forwardIfEquals(_ string: String) -> Bool {
        var testingIterator = self
        guard testingIterator.forwardAndCheckingIfEquals(string) else { return false }

        self = testingIterator
        return true
    }

    @discardableResult
    mutating func forwardAndCheckingIfEquals(_ string: String) -> Bool {
        var referenceIterator = string.unicodeScalars.makeIterator()
        while let referenceChar = referenceIterator.next() {
            guard referenceChar == self.next() else { return false }
        }
        return true
    }

    // source: http://www.cse.yorku.ca/~oz/hash.html
    mutating func hash(until stopChar: Unicode.Scalar) -> UInt64 {
        var forwardingIterator = self
        var hash: UInt64 = 5381
        while let referenceChar = forwardingIterator.next() {
            guard referenceChar != stopChar else { return hash }

            hash = (((hash &<< 5) &+ hash) &+ UInt64(referenceChar.value)) /* hash * 33 + c */
        }
        return hash
    }

    mutating func foward(untilAfter stopChar: Unicode.Scalar) {
        while let char = self.next(), char != stopChar {}
    }

    mutating func scanString(untilBefore stopChar: Unicode.Scalar) -> String {
        var scannedScalars = "".unicodeScalars
        var scanningIterator = self

        while let char = scanningIterator.next(), char != stopChar {
            self = scanningIterator
            scannedScalars.append(char)
        }
        return String(scannedScalars)
    }

    mutating func forwardUntilNextAttribute(stopBefore derminationChar: UnicodeScalar) -> Bool {
        var testingIterator = self
        while let referenceChar = self.next() {
            switch referenceChar {
            case " ", ";":
                return true
            case derminationChar:
                self = testingIterator
                return false
            default:
                testingIterator = self
                continue
            }
        }
        return false
    }

    mutating func skipWhiteSpace() {
        var testingIterator = self
        while let referenceChar = testingIterator.next() {
            switch referenceChar {
            case " ":
                break
            default:
                return
            }
            self = testingIterator
        }
    }

    mutating func skipStyleAttributeIgnoredCharacters() {
        var testingIterator = self
        while let referenceChar = testingIterator.next() {
            switch referenceChar {
            case "=", " ", ";", ":":
                break
            default:
                return
            }
            self = testingIterator
        }
    }

    mutating func parseFloat() -> CGFloat? {
        let decimalSeparator: UnicodeScalar = "."
        var result: CGFloat? = nil
        var parsingDecimals = false
        var parsingIterator = self
        var isNegative = false
        var decimalMultiplier: CGFloat = 0.1
        while let char = parsingIterator.next() {
            if result == nil && char == "-" {
                isNegative = true
                continue
            }
            // 48='0', 57='9'
            guard char.value >= 48 && char.value <= 57 || char == decimalSeparator else { break }
            guard char != decimalSeparator else {
                parsingDecimals = true
                continue
            }
            if parsingDecimals == false {
                result = (result ?? 0) * 10.0 + CGFloat(char.value - 48)
            } else {
                result = (result ?? 0) + CGFloat(char.value - 48) * decimalMultiplier
                decimalMultiplier = decimalMultiplier * 0.1
            }
            self = parsingIterator
        }
        guard let validResult = result else { return nil }

        return isNegative ? -validResult : validResult
    }

    func testNextCharacter() -> Unicode.Scalar? {
        var copiedIterator = self
        return copiedIterator.next()
    }
}

// MARK: - Color Parsing

extension String.UnicodeScalarView.Iterator {

    mutating func parseColor() -> Color? {
        var parsingIterator = self
        guard let firstChar = parsingIterator.next(), firstChar == "r" else { return nil }
        guard let secondChar = parsingIterator.next(), secondChar == "g" else { return nil }
        guard let thirdChar = parsingIterator.next(), thirdChar == "b" else { return nil }

        let fourthChar = parsingIterator.next()
        let parseRGBA = fourthChar == "a"
        if parseRGBA { _ = parsingIterator.next() }

        func skipIgnoredChars() {
            var testingIterator = parsingIterator
            while let referenceChar = testingIterator.next() {
                guard referenceChar == " " || referenceChar == "," else { return }

                parsingIterator = testingIterator
            }
        }

        func createColor(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> Color {
            return Color(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
        }

        skipIgnoredChars()
        guard let rValue = parsingIterator.parseFloat() else { return nil }

        skipIgnoredChars()
        guard let gValue = parsingIterator.parseFloat() else { return nil }

        skipIgnoredChars()
        guard let bValue = parsingIterator.parseFloat() else { return nil }

        guard parseRGBA else { return createColor(r: rValue, g: gValue, b: bValue) }

        skipIgnoredChars()
        guard let aValue = parsingIterator.parseFloat() else { return nil }

        return createColor(r: rValue, g: gValue, b: bValue, a: aValue)
    }
}

// MARK: - UnderlineStyle

extension String.UnicodeScalarView.Iterator {

    mutating func parseUnderlineStyle() -> NSUnderlineStyle? {
        guard let firstChar = self.testNextCharacter() else { return nil }

        switch firstChar {
        case "s":
            return self.forwardIfEquals("single") ? NSUnderlineStyle.styleSingle : nil
        case "d":
            return self.forwardIfEquals("double") ? NSUnderlineStyle.styleDouble : nil
        case "t":
            return self.forwardIfEquals("thick") ? NSUnderlineStyle.styleThick : nil
        default:
            return nil
        }
    }
}

// MARK: - Text Decoration

extension String.UnicodeScalarView.Iterator {

    mutating func parseTextDecoration() -> NSAttributedStringKey? {
        guard let firstChar = self.testNextCharacter() else { return nil }

        switch firstChar {
        case "u":
            return self.forwardIfEquals("underline") ? NSAttributedStringKey.underlineStyle : nil
        case "l":
            return self.forwardIfEquals("line-through") ? NSAttributedStringKey.strikethroughStyle : nil
        default:
            return nil
        }
    }
}

// MARK: - TextAlignment

extension String.UnicodeScalarView.Iterator {

    mutating func parseTextAlignment() -> NSTextAlignment? {
        guard let firstChar = self.testNextCharacter() else { return nil }

        switch firstChar {
        case "l":
            return self.forwardIfEquals("left") ? NSTextAlignment.left : nil
        case "r":
            return self.forwardIfEquals("right") ? NSTextAlignment.right  : nil
        case "j":
            return self.forwardIfEquals("justify") ? NSTextAlignment.justified  : nil
        case "c":
            return self.forwardIfEquals("center") ? NSTextAlignment.center  : nil
        default:
            return nil
        }
    }
}

// MARK: - Vertical Alignment

extension String.UnicodeScalarView.Iterator {
    
    mutating func parseVerticalAlignmentFromString() -> Int? {
        guard let firstChar = self.testNextCharacter() else { return nil }
        
        switch firstChar {
        case "s":
            if self.forwardIfEquals("sub") {
                return -1
            } else if self.forwardIfEquals("super") {
                return 1
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    mutating func parseVerticalAlignment() -> CGFloat? {
        return self.parseFloat()
    }
}

// MARK: - Baseline-Offset

extension String.UnicodeScalarView.Iterator {
    
    mutating func parseBaselineOffset() -> CGFloat? {
        return self.parseFloat()
    }
}

// MARK: - Font

extension String.UnicodeScalarView.Iterator {
    
    mutating func parseFontAttributes() -> (isBold: Bool, isItalic: Bool, points: CGFloat?, family: String?) {
        let isBold = self.forwardIfEquals("bold ")
        let isItalic = self.forwardIfEquals("italic ")
        
        guard let fontSize = self.parseFloat() else { return (isBold, isItalic, nil, nil) }
        
        self.forwardIfEquals("px \"")
        let familyName = self.scanString(untilBefore: "\"")
        
        return (isBold, isItalic, fontSize, familyName)
    }
    
    mutating func parsePostscriptFontName() -> String? {
        guard self.forwardIfEquals("\"") else { return nil }
        
        return self.scanString(untilBefore: "\"")
    }
}

// MARK: - Escaping

extension String.UnicodeScalarView.Iterator {
    
    mutating func parseEscapedChar() -> UnicodeScalar? {
        var parsingIterator = self
        var escapeChar: UnicodeScalar?
        
        guard let firstChar = parsingIterator.next() else { return nil }
        switch firstChar {
        case "a":
            if parsingIterator.forwardIfEquals("mp;") {
                escapeChar = "&"
            } else if parsingIterator.forwardIfEquals("pos;") {
                escapeChar = "'"
            } else {
                return nil
            }
        case "q":
            guard parsingIterator.forwardIfEquals("uot;") else { return nil }
            
            escapeChar = "\""
        case "l":
            guard parsingIterator.forwardIfEquals("t;") else { return nil }
            
            escapeChar = "<"
        case "g":
            guard parsingIterator.forwardIfEquals("t;") else { return nil }
            
            escapeChar = ">"
        default:
            return nil
        }
        
        self = parsingIterator
        return escapeChar
    }
}

// MARK: - Font Features

extension String.UnicodeScalarView.Iterator {
    
    mutating func parseFontFeatures() -> [[String: Int]] {
        var parsingIterator = self
        var features: [[String: Int]] = []
        var feature: [String: Int] = [:]
        var currentFeatureKey = FontDescriptor.FeatureKey.typeIdentifier
        
        while let char = parsingIterator.next() {
            guard char != ";" else { break }
            
            if char == "/" {
                self = parsingIterator
                continue
            }
            
            if char == " " {
                if feature.keys.count == 2 {
                    features.append(feature)
                    feature = [:]
                    currentFeatureKey = FontDescriptor.FeatureKey.typeIdentifier
                }
                self = parsingIterator
                continue
            }
            
            guard let featureValue = self.parseFloat() else { return features }
            
            feature[currentFeatureKey.rawValue] = Int(featureValue)
            currentFeatureKey = FontDescriptor.FeatureKey.selectorIdentifier
            parsingIterator = self
        }
        if feature.keys.count == 2 { features.append(feature) }
        
        return features
    }
}


// MARK: - URL

extension String.UnicodeScalarView.Iterator {
    
    mutating func parseURL() -> URL? {
        var parsingIterator = self
        var isFirstChar = true
        var urlChars = "".unicodeScalars
        while let char = parsingIterator.next() {
            guard char != "'" && char != "\"" else {
                if isFirstChar { continue } else { break }
            }
            isFirstChar = false
            if char == "&", let escapedChar = parsingIterator.parseEscapedChar() {
                urlChars.append(escapedChar)
            } else {
                urlChars.append(char)
            }
        }
        guard urlChars.isEmpty == false else { return nil }
        guard let url = URL(string: String(urlChars)) else { return nil }
        
        self = parsingIterator
        return url
    }
}
