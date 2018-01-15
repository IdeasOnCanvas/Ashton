//
//  Ashton.swift
//  Ashton
//
//  Created by Michael Schwarz on 16.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation
import Ashton.AshtonObjc

/// Transforms AttributedString into HTML in both directions
@objc
public final class Ashton: NSObject {

	public typealias HTML = String

    private static let reader = AshtonObjcHTMLReader()
    private static let writer = AshtonHTMLWriter()
    private static let mixedContentPreprocessor = AshtonObjcMixedContentPreprocessor()

    @objc
	public static func encode(_ attributedString: NSAttributedString) -> HTML {
        return Ashton.writer.encode(attributedString)
	}

    @objc
    public static func decode(_ html: HTML, containsMixedContent: Bool = false) -> NSAttributedString {
        let htmlString = containsMixedContent ? self.mixedContentPreprocessor.preprocessHTMLString(html) : html

        return Ashton.reader.decodeAttributedString(fromHTML: htmlString) ?? NSAttributedString()

		// swift implementation is substantially slower (using swift4 to compile)
        // return AshtonHTMLReader().decode(html) // swift implementation
	}
}
