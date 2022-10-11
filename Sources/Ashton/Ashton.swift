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

    internal static let reader = AshtonHTMLReader()
    internal static let writer = AshtonHTMLWriter()

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
    public static func decode(_ html: HTML, defaultAttributes: [NSAttributedString.Key: Any] = [:]) -> NSAttributedString {
        self.decode(html, defaultAttributes: defaultAttributes) { _ in }
    }

    /// Decodes a HTML representation into an NSAttributedString
    ///
    /// - Parameter html: The HTML representation to encode.
    /// - Parameter defaultAttributes: Attributes which are used if no attribute is specified in the HTML.
    /// - Parameter completionHandler: Called when the receiver did finish parsing. A result type containing parsing information gets passed in. This is called synchronously right before returning.
    /// - Returns: The decoded NSAttributedString.
    public static func decode(_ html: HTML, defaultAttributes: [NSAttributedString.Key: Any] = [:], completionHandler: AshtonHTMLReadCompletionHandler) -> NSAttributedString {
        return Ashton.reader.decode(html, defaultAttributes: defaultAttributes, completionHandler: completionHandler)
    }

    /// Clears decoding caches (e.g. already parsed and converted html style attribute strings are cached)
    @objc
    public static func clearCaches() {
        Ashton.reader.clearCaches()
    }
}
