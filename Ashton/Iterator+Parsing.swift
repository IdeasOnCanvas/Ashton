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
        var referenceIterator = string.unicodeScalars.makeIterator()
        while let referenceChar = referenceIterator.next() {
            guard referenceChar == testingIterator.next() else { return false }
        }
        self = testingIterator
        return true
    }

    mutating func foward(until stopChar: Unicode.Scalar) {
        var forwardingIterator = self
        while let char = forwardingIterator.next(), char != stopChar {
            self = forwardingIterator
        }
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
        var decimalMultiplier: CGFloat = 0.1
        while let char = parsingIterator.next() {
            // 48='0', 57='9'
            guard char.value >= 48 && char.value <= 57 || char == decimalSeparator else { return result }
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
        return result
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
