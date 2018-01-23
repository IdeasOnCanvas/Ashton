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


struct FontBuilder {
    var familyName: String?
    var postScriptName: String?
    var isBold: Bool = false
    var isItalic: Bool = false
    var pointSize: CGFloat?
    var fontFeatures: [[String: Any]]?
    
    static let fontCache = NSCache<NSString, Font>()
    
    func makeFont() -> Font? {
        guard let fontName = self.postScriptName ?? self.familyName else { return nil }
        guard let pointSize = self.pointSize else { return nil }
        
        let cacheKey = "\(fontName)\(pointSize)\(self.isItalic)\(self.isBold)"
        if let cachedFont = FontBuilder.fontCache.object(forKey: cacheKey as NSString) { return cachedFont }

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
        
        FontBuilder.fontCache.setObject(font, forKey: cacheKey as NSString)
        return font
    }
}
