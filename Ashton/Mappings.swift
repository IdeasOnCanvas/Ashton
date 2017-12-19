//
//  Mappings.swift
//  Ashton
//
//  Created by Michael Schwarz on 19.12.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif
import Foundation


// Defines mappings between HTML attributes and AttributedString keys
struct Mappings {

    struct UnderlineStyle {
        static let encode: [NSUnderlineStyle: String] = [
            .styleSingle: "single",
            .styleDouble: "double",
            .styleThick: "thick"
        ]
        static let decode: [String: NSUnderlineStyle] = [
            "single": .styleSingle,
            "double": .styleDouble,
            "thick": .styleThick
        ]
    }
}
