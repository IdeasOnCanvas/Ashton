//
//  CrossPlatformCompatibility.swift
//  Ashton
//
//  Created by Michael Schwarz on 11.12.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

#if os(iOS)
    import UIKit
    typealias Font = UIFont
    typealias FontDescriptor = UIFontDescriptor
    typealias FontDescriptorSymbolicTraits = UIFontDescriptor.SymbolicTraits
    typealias Color = UIColor

    extension UIFont {
        var cpFamilyName: String { return self.familyName }
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
        var cpFamilyName: String { return self.familyName ?? "" }
    }

    extension NSFontDescriptor {
        var cpPostscriptName: String { return self.postscriptName ?? "" }
    }

    extension FontDescriptor.FeatureKey {
        static let cpTypeIdentifier = FontDescriptor.FeatureKey("CTFeatureTypeIdentifier")
    }
#endif
