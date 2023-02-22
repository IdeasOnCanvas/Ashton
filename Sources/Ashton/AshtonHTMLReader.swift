//
//  AshtonHTMLReader.swift
//  Ashton
//
//  Created by Michael Schwarz on 17.09.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

import Foundation
import CoreGraphics

public typealias AshtonHTMLReadCompletionHandler = (_ readResult: AshtonHTMLReadResult) -> Void

@objc
public final class AshtonHTMLReadResult: NSObject {
    public let unknownFonts: Set<String>

    public init(unknownFonts: [String]) {
        // We accept an `Array` on the call site (because arrays are a bit more convenient)
        // but convert to `Set` here for deduplication.
        self.unknownFonts = Set(unknownFonts)
    }
}

public final class AshtonHTMLReader: NSObject {

    private var attributesStack: [[NSAttributedString.Key: Any]] = []
    private var output: NSMutableAttributedString!
    private var parsedTags: [AshtonXMLParser.Tag] = []
    private var unknownFonts: [String] = []

    // MARK: - Properties

    private(set) var fontBuilderCache: FontBuilder.FontCache
    private(set) var xmlParser: AshtonXMLParser

    // MARK: - Lifecycle

    public override convenience init() {
        self.init(fontBuilderCache: .init(), styleCache: .init())
    }

    init(fontBuilderCache: FontBuilder.FontCache, styleCache: AshtonXMLParser.StyleAttributesCache) {
        let fontBuilderCache = fontBuilderCache
        self.fontBuilderCache = fontBuilderCache
        self.xmlParser = .init(styleAttributesCache: styleCache, fontBuilderCache: fontBuilderCache)
    }

    // MARK: - 

    public func decode(_ html: Ashton.HTML, defaultAttributes: [NSAttributedString.Key: Any] = [:], completionHandler: AshtonHTMLReadCompletionHandler) -> NSAttributedString {
        self.output = NSMutableAttributedString()
        self.parsedTags = []
        self.attributesStack = [defaultAttributes]
        self.unknownFonts = []
        
        self.xmlParser.delegate = self
        self.xmlParser.parse(string: html)
        // Since `.parse` is a synchronous call, we can simply run the completion handler here.
        // This allows us to stick with the default, implicit `@noescape` behavior.
        completionHandler(AshtonHTMLReadResult(unknownFonts: self.unknownFonts))

        return self.output
    }

    func clearCaches() {
        self.fontBuilderCache = .init()
        self.xmlParser = .init(styleAttributesCache: .init(), fontBuilderCache: self.fontBuilderCache)
    }
}

// MARK: - AshtonXMLParserDelegate

extension AshtonHTMLReader: AshtonXMLParserDelegate {
    
    func didParseContent(_ parser: AshtonXMLParser, string: String) {
        self.appendToOutput(string)
    }
    
    func didOpenTag(_ parser: AshtonXMLParser, name: AshtonXMLParser.Tag, attributes: [NSAttributedString.Key : Any]?) {
        var attributes = attributes ?? [:]
        let currentAttributes = self.attributesStack.last ?? [:]

        if let derivedFontBuilder = self.makeDerivedFontBuilder(forTag: name) {
            attributes[.font] = derivedFontBuilder.makeFont()
        }

        attributes.merge(currentAttributes, uniquingKeysWith: { (current, _) in current })

        self.attributesStack.append(attributes)
        self.parsedTags.append(name)
    }
    
    func didCloseTag(_ parser: AshtonXMLParser) {
        guard self.attributesStack.isEmpty == false, self.parsedTags.isEmpty == false else {
            return
        }

        self.attributesStack.removeLast()
    }

    func didEncounterUnknownFont(_ parser: AshtonXMLParser, fontName: String) {
        self.unknownFonts.append(fontName)
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

    func makeDerivedFontBuilder(forTag tag: AshtonXMLParser.Tag) -> FontBuilder? {
        guard tag == .strong || tag == .em else { return nil }
        guard let currentFont = self.attributesStack.last?[.font] as? Font else { return nil }

        let fontBuilder = FontBuilder(fontCache: self.fontBuilderCache)
        fontBuilder.configure(with: currentFont)
        fontBuilder.isBold = (tag == .strong)
        fontBuilder.isItalic = (tag == .em)
        return fontBuilder
    }
}
