//
//  CrossPlatformCompatibility.swift
//  Ashton
//
//  Created by Michael Schwarz on 11.12.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

#if os(iOS) || os(visionOS)
import UIKit
typealias Font = UIFont
typealias FontDescriptor = UIFontDescriptor
typealias FontDescriptorSymbolicTraits = UIFontDescriptor.SymbolicTraits
typealias Color = UIColor

extension UIFont {
    class var cpFamilyNames: [String] { return UIFont.familyNames }
    var cpFamilyName: String { return self.familyName }

    class func cpFontNames(forFamilyName familyName: String) -> [String] {
        return UIFont.fontNames(forFamilyName: familyName)
    }
}

extension UIFontDescriptor {
    var cpPostscriptName: String { return self.postscriptName }
}

extension NSAttributedString.Key {
    static let superscript = NSAttributedString.Key(rawValue: "NSSuperScript")
}

extension FontDescriptor.FeatureKey {
    static let selectorIdentifier = FontDescriptor.FeatureKey("CTFeatureSelectorIdentifier")
    static let cpTypeIdentifier = FontDescriptor.FeatureKey("CTFeatureTypeIdentifier")
}

#elseif os(macOS)
import AppKit
typealias Font = NSFont
typealias FontDescriptor = NSFontDescriptor
typealias FontDescriptorSymbolicTraits = NSFontDescriptor.SymbolicTraits
typealias Color = NSColor

extension NSFont {
    class var cpFamilyNames: [String] { return NSFontManager.shared.availableFontFamilies }
    var cpFamilyName: String { return self.familyName ?? "" }

    class func cpFontNames(forFamilyName familyName: String) -> [String] {
        let fontManager = NSFontManager.shared
        let availableMembers = fontManager.availableMembers(ofFontFamily: familyName)
        return availableMembers?.compactMap { member in
            let memberArray = member as Array<Any>
            return memberArray.first as? String
            } ?? []
    }
}

extension NSFontDescriptor {
    var cpPostscriptName: String { return self.postscriptName ?? "" }
}

extension FontDescriptor.FeatureKey {
    static let cpTypeIdentifier = FontDescriptor.FeatureKey("CTFeatureTypeIdentifier")
}
#endif
