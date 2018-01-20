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
        if let attributes = self.attributesStack.last {
            self.output.append(NSAttributedString(string: string, attributes: attributes))
        } else {
            self.output.append(NSAttributedString(string: string))
        }
    }
    
    func didOpenTag(_ parser: AshtonXMLParser, name: AshtonXMLParser.Tag, attributes: [NSAttributedStringKey : Any]?) {
        var attributes = attributes ?? [:]
        let lastAttributes = self.attributesStack.last ?? [:]
        attributes.merge(lastAttributes, uniquingKeysWith: { $1 })
        self.attributesStack.append(attributes)
    }
    
    func didCloseTag(_ parser: AshtonXMLParser) {
        guard self.attributesStack.isEmpty == false else { return }
        
        self.attributesStack.removeLast(1)
    }
}
