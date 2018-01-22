//
//  FontBuilder.swift
//  Ashton
//
//  Created by Michael Schwarz on 20.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

import Foundation


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
        
        let fontDescriptor = FontDescriptor(fontAttributes: [FontDescriptor.AttributeName.name: fontName])
        let fontDescriptorWithTraits: FontDescriptor?
        
        var symbolicTraits = FontDescriptorSymbolicTraits()
        if self.postScriptName == nil {
            #if os(iOS)
                if self.isBold { symbolicTraits.insert(.traitBold) }
                if self.isItalic { symbolicTraits.insert(.traitItalic) }
            #elseif os(macOS)
                if self.isBold { symbolicTraits.insert(.bold) }
                if self.isItalic { symbolicTraits.insert(.italic) }
            #endif
            fontDescriptorWithTraits = fontDescriptor.withSymbolicTraits(symbolicTraits)
        } else {
            fontDescriptorWithTraits = nil
        }
        
        #if os(iOS)
            let font = Font(descriptor: fontDescriptorWithTraits ?? fontDescriptor, size: pointSize)
        #elseif os(macOS)
            guard let font = Font(descriptor: fontDescriptorWithTraits ?? fontDescriptor, size: pointSize) else { return nil }
        #endif
        
        FontBuilder.fontCache.setObject(font, forKey: cacheKey as NSString)
        return font
    }
}
