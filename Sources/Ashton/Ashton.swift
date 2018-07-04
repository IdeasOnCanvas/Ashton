//
//  Ashton.swift
//  Ashton
//
//  Created by Michael Schwarz on 16.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation


/// Transforms NSAttributedString <--> HTML
@objc
public final class Ashton: NSObject {

    public typealias HTML = String

    private static let reader = AshtonHTMLReader()
    private static let writer = AshtonHTMLWriter()

    /// Encodes an NSAttributedString into a HTML representation
    ///
    /// - Parameter attributedString: The NSAttributedString to encode
    /// - Returns: The HTML representation
    @objc
    public static func encode(_ attributedString: NSAttributedString) -> HTML {
        return Ashton.writer.encode(attributedString)
    }

    /// Decodes a HTML representation into an NSAttributedString
    ///
    /// - Parameter html: The HTML representation to encode
    /// - Parameter defaultAttributes: Attributes which are used if no attribute is specified in the HTML
    /// - Returns: The decoded NSAttributedString
    @objc
    public static func decode(_ html: HTML, defaultAttributes: [NSAttributedStringKey: Any] = [:]) -> NSAttributedString {
        return Ashton.reader.decode(html, defaultAttributes: defaultAttributes)
    }

    /// Clears decoding caches (e.g. already parsed and converted html style attribute strings are cached)
    @objc
    public static func clearCaches() {
        Ashton.reader.clearCaches()
    }
}
