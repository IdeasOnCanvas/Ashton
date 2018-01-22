//
//  AshtonHTMLReader.swift
//  Ashton
//
//  Created by Michael Schwarz on 17.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation
import Ashton.TBXML
#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif


final class AshtonHTMLReader: NSObject {

	private var attributesStack: [[NSAttributedStringKey: Any]] = []
	private var output: NSMutableAttributedString!
    private var parsedTags: [AshtonXMLParser.Tag] = []
    private var appendNewlineBeforeNextContent = false

	func decode(_ html: Ashton.HTML) -> NSAttributedString {
        self.output = NSMutableAttributedString()
        
        let xmlParser = AshtonXMLParser(xmlString: html)
		xmlParser.delegate = self
        xmlParser.parse()

		return self.output
	}
}

// MARK: - AshtonXMLParserDelegate

extension AshtonHTMLReader: AshtonXMLParserDelegate {
    
    func didParseContent(_ parser: AshtonXMLParser, string: String) {
        self.appendToOutput(string)
    }
    
    func didOpenTag(_ parser: AshtonXMLParser, name: AshtonXMLParser.Tag, attributes: [NSAttributedStringKey : Any]?) {
        if self.appendNewlineBeforeNextContent {
            self.appendToOutput("\n")
            self.appendNewlineBeforeNextContent = false
            self.attributesStack.removeLast()
        }

        var attributes = attributes ?? [:]
        let lastAttributes = self.attributesStack.last ?? [:]
        attributes.merge(lastAttributes, uniquingKeysWith: { $1 })

        self.attributesStack.append(attributes)
        self.parsedTags.append(name)
    }
    
    func didCloseTag(_ parser: AshtonXMLParser) {
        guard self.attributesStack.isEmpty == false else { return }

        if self.parsedTags.removeLast() == .p {
            if self.appendNewlineBeforeNextContent == true {
                self.appendToOutput("\n")
            } else {
                self.appendNewlineBeforeNextContent = true
            }
        } else {
            self.attributesStack.removeLast()
        }
    }
}

// MARK: - Private

private extension AshtonHTMLReader {

    func appendToOutput(_ string: String) {
        if let attributes = self.attributesStack.last, attributes.isEmpty == false {
            self.output.append(NSAttributedString(string: string, attributes: attributes))
        } else {
            self.output.append(NSAttributedString(string: string))
        }
    }
}
