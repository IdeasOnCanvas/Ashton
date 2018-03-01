//
//  FontBuilder.swift
//  Ashton
//
//  Created by Michael Schwarz on 20.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreText


/// Creates a NS/UIFont
final class FontBuilder {

    // MARK: - Properties

    static var fontCache: [String: Font] = [:]

    var fontName: String? { return self.postScriptName ?? self.familyName }
    var familyName: String?
    var postScriptName: String?
    var isBold: Bool = false
    var isItalic: Bool = false
    var pointSize: CGFloat?
    var fontFeatures: [[String: Any]]?
    var cacheKey: String {
        guard let familyName = self.fontName else { return "" }
        guard let pointSize = self.pointSize else { return "" }

        return "\(familyName)\(pointSize)\(self.isBold)\(self.isItalic)\(self.fontFeatures?.description ?? "")"
    }

    // MARK: - FontBuilder
    
    func makeFont() -> Font? {
        guard let fontName = self.fontName else { return nil }
        guard let pointSize = self.pointSize else { return nil }

        let cacheKey = self.cacheKey
        if let cachedFont = FontBuilder.fontCache[cacheKey] {
            return cachedFont
        }

        var attributes: [FontDescriptor.AttributeName: Any] = [FontDescriptor.AttributeName.name: fontName]
        if let fontFeatures = fontFeatures {
           attributes[.featureSettings] = fontFeatures
        }

        var fontDescriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)

        if self.postScriptName == nil {
            var symbolicTraits = CTFontSymbolicTraits()
            #if os(iOS)
                if self.isBold { symbolicTraits.insert(.boldTrait) }
                if self.isItalic { symbolicTraits.insert(.italicTrait) }
            #elseif os(macOS)
                if self.isBold { symbolicTraits.insert(.boldTrait) }
                if self.isItalic { symbolicTraits.insert(.italicTrait) }
            #endif
            fontDescriptor = CTFontDescriptorCreateCopyWithSymbolicTraits(fontDescriptor, symbolicTraits, symbolicTraits) ?? fontDescriptor
        }

        let font = CTFontCreateWithFontDescriptor(fontDescriptor, pointSize, nil) as Font
        
        FontBuilder.fontCache[cacheKey] = font
        return font
    }
}
