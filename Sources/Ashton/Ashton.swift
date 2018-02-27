//
//  Ashton.swift
//  Ashton
//
//  Created by Michael Schwarz on 16.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation


/// Transforms AttributedString into HTML in both directions
@objc
public final class Ashton: NSObject {

	public typealias HTML = String

    private static let reader = AshtonHTMLReader()
    private static let writer = AshtonHTMLWriter()

    @objc
	public static func encode(_ attributedString: NSAttributedString) -> HTML {
        return Ashton.writer.encode(attributedString)
	}

    @objc
    public static func decode(_ html: HTML, defaultAttributes: [NSAttributedStringKey: Any] = [:]) -> NSAttributedString {
        return Ashton.reader.decode(html, defaultAttributes: defaultAttributes)
	}

    public static func clearCaches() {
        Ashton.reader.clearCaches()
    }
}
