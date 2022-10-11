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

    typealias FontCache = Cache<String, Font>

    // MARK: - Properties

    var fontCache: FontCache
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

    // MARK: - Lifecycle

    init(fontCache: FontCache? = nil) {
        self.fontCache = fontCache ?? .init()
    }

    // MARK: - FontBuilder

    func configure(with font: Font) {
        self.familyName = font.familyName
        self.pointSize = font.pointSize
    }
    
    func makeFont() -> Font? {
        guard let fontName = self.fontName else { return nil }
        guard let pointSize = self.pointSize else { return nil }

        let cacheKey = self.cacheKey
        if let cachedFont = self.fontCache[cacheKey] {
            return cachedFont
        }

        var attributes: [FontDescriptor.AttributeName: Any] = [FontDescriptor.AttributeName.name: fontName]
        if let fontFeatures = self.fontFeatures {
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
        #if os(macOS)
        // on macOS we have to do this conversion CTFont -> NSFont, otherwise we have wrong glyph spacing for some (arabic) fonts when rendering on device
        let descriptor = font.fontDescriptor
        let convertedFont = Font(descriptor: descriptor, size: descriptor.pointSize)
        self.fontCache[cacheKey] = convertedFont
        return convertedFont
        #else
        FontBuilder.fontCache[cacheKey] = font
        return font
        #endif
    }
}
