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

    mutating func parseColor() -> Color? {
        var parsingIterator = self

        return nil
    }

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

    func testNextCharacter() -> Unicode.Scalar? {
        var copiedIterator = self
        return copiedIterator.next()
    }
}

