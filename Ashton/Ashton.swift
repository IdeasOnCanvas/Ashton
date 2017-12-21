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
public final class Ashton {

	public typealias HTML = String

	public static func encode(_ attributedString: NSAttributedString) -> HTML {
		return AshtonHTMLWriter().encode(attributedString)
	}

	public static func decode(_ html: HTML) -> NSAttributedString {
        return AshtonObjcHTMLReader().decodeAttributedString(fromHTML: html)
		//return AshtonHTMLReader().decode(html) // swift implementation
	}
}
