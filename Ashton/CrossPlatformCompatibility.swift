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
    typealias FontDescriptorSymbolicTraits = UIFontDescriptorSymbolicTraits
    typealias Color = UIColor
#elseif os(macOS)
    import AppKit
    typealias Font = NSFont
    typealias FontDescriptor = NSFontDescriptor
    typealias FontDescriptorSymbolicTraits = NSFontDescriptor.SymbolicTraits
    typealias Color = NSColor
#endif
