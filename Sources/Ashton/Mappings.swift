//
//  Mappings.swift
//  Ashton
//
//  Created by Michael Schwarz on 19.12.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

#if os(iOS) || (compiler(>=5.9) && os(visionOS))
    import UIKit
#elseif os(macOS)
    import AppKit
#endif
import Foundation


// Defines mappings between HTML attributes and AttributedString keys
struct Mappings {

    struct UnderlineStyle {
        static let encode: [NSUnderlineStyle.RawValue: String] = [
            NSUnderlineStyle.single.rawValue: "single",
            NSUnderlineStyle.double.rawValue: "double",
            NSUnderlineStyle.thick.rawValue: "thick"
        ]
    }

    struct TextAlignment {
        static let encode: [NSTextAlignment: String] = [
            .left: "left",
            .center: "center",
            .right: "right",
            .justified: "justify"
        ]
    }
}
