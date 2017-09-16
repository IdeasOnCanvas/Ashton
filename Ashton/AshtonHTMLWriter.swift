//
//  AshtonHTMLWriter.swift
//  Ashton
//
//  Created by Michael Schwarz on 16.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation


final class AshtonHTMLWriter {

	public func encode(_ attributedString: NSAttributedString) -> Ashton.HTML {
		let paragraphs = self.getParagraphs(attributedString.string)
		return String(paragraphs.flatMap { "<p>\($0)</p>" })
	}
}

// MARK: - Private

private extension AshtonHTMLWriter {

	func getParagraphs(_ string: String) -> [String] {
		var (paragraphStart, paragraphEnd, contentsEnd) = (string.startIndex, string.startIndex, string.startIndex)
		var array = [String]()
		let length = string.endIndex

		while paragraphEnd < length {
			string.getParagraphStart(&paragraphStart, end: &paragraphEnd, contentsEnd: &contentsEnd, for: paragraphEnd...paragraphEnd)
			array.append(String(string[paragraphStart..<contentsEnd]))
		}
		return array
	}
}
