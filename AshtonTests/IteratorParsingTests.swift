//
//  IteratorParsingTests.swift
//  AshtonTests
//
//  Created by Michael Schwarz on 19.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

import XCTest
@testable import Ashton


final class IteratorParsingTests: XCTestCase {

    func testRGBAColorParsing() {
        let sample = "rgba(255, 20, 128, 0.953000)"
        var iterator = sample.unicodeScalars.makeIterator()
        let color = iterator.parseColor()

        XCTAssertNotNil(color)
        let components = color!.cgColor.components!

        XCTAssertTrue(components[0].almostEquals(1.0))
        XCTAssertTrue(components[1].almostEquals(20.0 / 255.0))
        XCTAssertTrue(components[2].almostEquals(128.0 / 255.0))
        XCTAssertTrue(components[3].almostEquals(0.953))
    }

    func testRGBColorParsing() {
        let sample = "rgb(88, 96, 105)"
        var iterator = sample.unicodeScalars.makeIterator()
        let color = iterator.parseColor()

        XCTAssertNotNil(color)
        let components = color!.cgColor.components!

        XCTAssertTrue(components[0].almostEquals(88.0 / 255.0))
        XCTAssertTrue(components[1].almostEquals(96.0 / 255.0))
        XCTAssertTrue(components[2].almostEquals(105.0 / 255.0))
        XCTAssertTrue(components[3].almostEquals(1.0))
    }

    func testNonValidColorParsing() {
        let sample = "1jdslk(fa, 96, fd)"
        var iterator = sample.unicodeScalars.makeIterator()
        let color = iterator.parseColor()

        XCTAssertNil(color)
        XCTAssertEqual(iterator.next(), "1")
    }

    func testUnderlineStyleParsing() {
        let thick = "thick;"
        var iterator = thick.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator.parseUnderlineStyle(), NSUnderlineStyle.styleThick)

        let single = "single"
        var iterator2 = single.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator2.parseUnderlineStyle(), NSUnderlineStyle.styleSingle)

        let double = "double"
        var iterator3 = double.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator3.parseUnderlineStyle(), NSUnderlineStyle.styleDouble)

        let quark = "quark"
        var iterator4 = quark.unicodeScalars.makeIterator()
        XCTAssertNil(iterator4.parseUnderlineStyle())
    }

    func testTextDecorationStyleParsing() {
        let strikethrough = "line-through;"
        var iterator = strikethrough.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator.parseTextDecoration(), NSAttributedStringKey.strikethroughStyle)

        let underline = "underline"
        var iterator2 = underline.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator2.parseTextDecoration(), NSAttributedStringKey.underlineStyle)

        let quark = "quark"
        var iterator3 = quark.unicodeScalars.makeIterator()
        XCTAssertNil(iterator3.parseTextDecoration())
    }

    func testTextAlignment() {
        let left = "left;"
        var iterator = left.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator.parseTextAlignment(), NSTextAlignment.left)

        let right = "right"
        var iterator2 = right.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator2.parseTextAlignment(), NSTextAlignment.right)

        let justify = "justify"
        var iterator3 = justify.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator3.parseTextAlignment(), NSTextAlignment.justified)

        let center = "center"
        var iterator4 = center.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator4.parseTextAlignment(), NSTextAlignment.center)

        let quark = "quark"
        var iterator5 = quark.unicodeScalars.makeIterator()
        XCTAssertNil(iterator5.parseTextAlignment())
    }
    
    func testVerticalAlignment() {
        let superattribute = "super;"
        var iterator = superattribute.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator.parseVerticalAlignment(), 1)
        
        let sub = "sub"
        var iterator2 = sub.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator2.parseVerticalAlignment(), -1)
        
        let quark = "quark"
        var iterator5 = quark.unicodeScalars.makeIterator()
        XCTAssertNil(iterator5.parseVerticalAlignment())
    }
}


// MARK: - Private

private extension CGFloat {

    func almostEquals(_ other: CGFloat) -> Bool {
        return fabs(self - other) <= CGFloat.ulpOfOne
    }
}
