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
        XCTAssertEqual(iterator.parseUnderlineStyle(), NSUnderlineStyle.thick)

        let single = "single"
        var iterator2 = single.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator2.parseUnderlineStyle(), NSUnderlineStyle.single)

        let double = "double"
        var iterator3 = double.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator3.parseUnderlineStyle(), NSUnderlineStyle.double)

        let quark = "quark"
        var iterator4 = quark.unicodeScalars.makeIterator()
        XCTAssertNil(iterator4.parseUnderlineStyle())
        XCTAssertEqual(iterator4.next(), "q")
    }

    func testTextDecorationStyleParsing() {
        let strikethrough = "line-through;"
        var iterator = strikethrough.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator.parseTextDecoration(), NSAttributedString.Key.strikethroughStyle)

        let underline = "underline"
        var iterator2 = underline.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator2.parseTextDecoration(), NSAttributedString.Key.underlineStyle)

        let quark = "quark"
        var iterator3 = quark.unicodeScalars.makeIterator()
        XCTAssertNil(iterator3.parseTextDecoration())
        XCTAssertEqual(iterator3.next(), "q")
    }

    func testTextAlignmentParsing() {
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
        XCTAssertEqual(iterator5.next(), "q")
    }
    
    func testVerticalAlignmentFromStringParsing() {
        let superattribute = "super;"
        var iterator = superattribute.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator.parseVerticalAlignmentFromString(), 1)
        
        let sub = "sub"
        var iterator2 = sub.unicodeScalars.makeIterator()
        XCTAssertEqual(iterator2.parseVerticalAlignmentFromString(), -1)
        
        let quark = "quark"
        var iterator5 = quark.unicodeScalars.makeIterator()
        XCTAssertNil(iterator5.parseVerticalAlignmentFromString())
        XCTAssertEqual(iterator5.next(), "q")
    }
    
    func testVerticalAlignmentParsing() {
        let baselineOffset = "2.5;"
        var iterator = baselineOffset.unicodeScalars.makeIterator()
        XCTAssertTrue(iterator.parseVerticalAlignment()!.almostEquals(2.5))
        
        let baselineOffset2 = "-1.0"
        var iterator2 = baselineOffset2.unicodeScalars.makeIterator()
        XCTAssertTrue(iterator2.parseVerticalAlignment()!.almostEquals(-1.0))
        
        let quark = "quark"
        var iterator3 = quark.unicodeScalars.makeIterator()
        XCTAssertNil(iterator3.parseVerticalAlignment())
        XCTAssertEqual(iterator3.next(), "q")
    }
    
    func testBaselineOffsetParsing() {
        let baselineOffset = "1.5;"
        var iterator = baselineOffset.unicodeScalars.makeIterator()
        XCTAssertTrue(iterator.parseBaselineOffset()!.almostEquals(1.5))
        
        let baselineOffset2 = "1"
        var iterator2 = baselineOffset2.unicodeScalars.makeIterator()
        XCTAssertTrue(iterator2.parseBaselineOffset()!.almostEquals(1.0))
        
        let quark = "quark"
        var iterator3 = quark.unicodeScalars.makeIterator()
        XCTAssertNil(iterator3.parseBaselineOffset())
        XCTAssertEqual(iterator3.next(), "q")
    }
    
    func testFontParsing() {
        let sampleFont = "bold italic 14px \"Helvetica\""
        var iterator = sampleFont.unicodeScalars.makeIterator()
        let fontAttributes = iterator.parseFontAttributes()
        XCTAssertEqual(fontAttributes.isBold, true)
        XCTAssertEqual(fontAttributes.isItalic, true)
        XCTAssertTrue(fontAttributes.points!.almostEquals(14.0))
        XCTAssertEqual(fontAttributes.family!, "Helvetica")
        
        let sample2 = "italic 12.5px \"Helvetica\", \"Arial\", sans-serif; "
        var iterator2 = sample2.unicodeScalars.makeIterator()
        let fontAttributes2 = iterator2.parseFontAttributes()
        XCTAssertEqual(fontAttributes2.isBold, false)
        XCTAssertEqual(fontAttributes2.isItalic, true)
        XCTAssertTrue(fontAttributes2.points!.almostEquals(12.5))
        XCTAssertEqual(fontAttributes2.family!, "Helvetica")
        
        let sample3 = "quark "
        var iterator3 = sample3.unicodeScalars.makeIterator()
        let fontAttributes3 = iterator3.parseFontAttributes()
        XCTAssertEqual(fontAttributes3.isBold, false)
        XCTAssertEqual(fontAttributes3.isItalic, false)
        XCTAssertNil(fontAttributes3.points)
        XCTAssertNil(fontAttributes3.family)
    }
    
    func testPostscriptFontNameParsing() {
        let sampleFontName = "\"Helvetica\""
        var iterator = sampleFontName.unicodeScalars.makeIterator()
        let fontName = iterator.parsePostscriptFontName()
        XCTAssertEqual("Helvetica", fontName)
        
        let quark = "quark"
        var iterator2 = quark.unicodeScalars.makeIterator()
        XCTAssertNil(iterator2.parseBaselineOffset())
        XCTAssertEqual(iterator2.next(), "q")
    }
    
    func testURLParsing() {
        let sampleURL = "\'www.google.at\'"
        var iterator = sampleURL.unicodeScalars.makeIterator()
        let url = iterator.parseURL()
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.absoluteString, "www.google.at")

        let sampleURL2 = "www.google.at\""
        var iterator2 = sampleURL2.unicodeScalars.makeIterator()
        let url2 = iterator2.parseURL()
        XCTAssertNotNil(url2)
        XCTAssertEqual(url2!.absoluteString, "www.google.at")
    }
    
    func testEscaping() {
        var scanned = "".unicodeScalars
        let sampleString = "Hello & World &amp; this &quot;is&quot; 3 &gt; 2; 4 &lt; &apos;2&apos;"
        var iterator = sampleString.unicodeScalars.makeIterator()
        while let char = iterator.next() {
            if char == "&", let escapedChar = iterator.parseEscapedChar() {
                scanned.append(escapedChar)
            } else {
                scanned.append(char)
            }
        }
        XCTAssertEqual(String(scanned), "Hello & World & this \"is\" 3 > 2; 4 < '2'")
    }
    
    func testFontFeaturesParsing() {
        let sampleFeatures = "2/1 12/2 4/2"
        var iterator = sampleFeatures.unicodeScalars.makeIterator()
        let features = iterator.parseFontFeatures()
        XCTAssertNotNil(features)
        XCTAssertEqual(features.count, 3)
        XCTAssertEqual(features[0][FontDescriptor.FeatureKey.cpTypeIdentifier.rawValue], 2)
        XCTAssertEqual(features[0][FontDescriptor.FeatureKey.selectorIdentifier.rawValue], 1)
        XCTAssertEqual(features[1][FontDescriptor.FeatureKey.cpTypeIdentifier.rawValue], 12)
        XCTAssertEqual(features[1][FontDescriptor.FeatureKey.selectorIdentifier.rawValue], 2)
        XCTAssertEqual(features[2][FontDescriptor.FeatureKey.cpTypeIdentifier.rawValue], 4)
        XCTAssertEqual(features[2][FontDescriptor.FeatureKey.selectorIdentifier.rawValue], 2)
        
        let sampleFeatures2 = "2/0  12/32  4/2"
        var iterator2 = sampleFeatures2.unicodeScalars.makeIterator()
        let features2 = iterator2.parseFontFeatures()
        XCTAssertNotNil(features2)
        XCTAssertEqual(features2.count, 3)
        XCTAssertEqual(features2[0][FontDescriptor.FeatureKey.cpTypeIdentifier.rawValue], 2)
        XCTAssertEqual(features2[0][FontDescriptor.FeatureKey.selectorIdentifier.rawValue], 0)
        XCTAssertEqual(features2[1][FontDescriptor.FeatureKey.cpTypeIdentifier.rawValue], 12)
        XCTAssertEqual(features2[1][FontDescriptor.FeatureKey.selectorIdentifier.rawValue], 32)
        XCTAssertEqual(features2[2][FontDescriptor.FeatureKey.cpTypeIdentifier.rawValue], 4)
        XCTAssertEqual(features2[2][FontDescriptor.FeatureKey.selectorIdentifier.rawValue], 2)
    }

    func testHashing() {
        #if os(macOS)
        let fonts = Self.sampleFontNames.components(separatedBy: .newlines)
        #elseif os(iOS)
        let fontFamilies = Font.familyNames
        var fonts: [String] = []
        for family in fontFamilies {
            fonts += Font.fontNames(forFamilyName: family)
        }
        #endif
        var hashes: [Int: String] = [:]
        var collisions: [(String, String)] = []
        for fontname in fonts {
            var iterator = ("font: " + fontname + "'").unicodeScalars.makeIterator()
            let hash = iterator.hash(until: "'")
            if let existingFont = hashes[hash] {
                collisions.append((existingFont, fontname))
            } else {
                hashes[hash] = fontname
            }
        }
        XCTAssertEqual(collisions.count, 0)
    }
}


// MARK: - Private

private extension CGFloat {

    func almostEquals(_ other: CGFloat) -> Bool {
        return abs(self - other) <= CGFloat.ulpOfOne
    }
}

private extension IteratorParsingTests {

    static let sampleFontNames: String = """
    Apple Braille Outline 6 Dot.ttf
    Apple Braille Outline 8 Dot.ttf
    Apple Braille Pinpoint 6 Dot.ttf
    Apple Braille Pinpoint 8 Dot.ttf
    Apple Braille.ttf
    Apple Color Emoji.ttc
    Apple Symbols.ttf
    AppleSDGothicNeo.ttc
    AquaKana.ttc
    ArabicUIDisplay.ttc
    ArabicUIText.ttc
    ArialHB.ttc
    Avenir Next Condensed.ttc
    Avenir Next.ttc
    Avenir.ttc
    Courier.dfont
    GeezaPro.ttc
    Geneva.dfont
    HelveLTMM
    Helvetica.ttc
    HelveticaNeue.ttc
    HelveticaNeueDeskInterface.ttc
    Hiragino Sans GB.ttc
    Keyboard.ttf
    Kohinoor.ttc
    KohinoorBangla.ttc
    KohinoorTelugu.ttc
    LastResort.otf
    LucidaGrande.ttc
    MarkerFelt.ttc
    Menlo.ttc
    Monaco.dfont
    Noteworthy.ttc
    NotoNastaliq.ttc
    Optima.ttc
    Palatino.ttc
    PingFang.ttc
    SFCompactDisplay-Black.otf
    SFCompactDisplay-Bold.otf
    SFCompactDisplay-Heavy.otf
    SFCompactDisplay-Light.otf
    SFCompactDisplay-Medium.otf
    SFCompactDisplay-Regular.otf
    SFCompactDisplay-Semibold.otf
    SFCompactDisplay-Thin.otf
    SFCompactDisplay-Ultralight.otf
    SFCompactRounded-Black.otf
    SFCompactRounded-Bold.otf
    SFCompactRounded-Heavy.otf
    SFCompactRounded-Light.otf
    SFCompactRounded-Medium.otf
    SFCompactRounded-Regular.otf
    SFCompactRounded-Semibold.otf
    SFCompactRounded-Thin.otf
    SFCompactRounded-Ultralight.otf
    SFCompactText-Bold.otf
    SFCompactText-BoldItalic.otf
    SFCompactText-Heavy.otf
    SFCompactText-HeavyItalic.otf
    SFCompactText-Light.otf
    SFCompactText-LightItalic.otf
    SFCompactText-Medium.otf
    SFCompactText-MediumItalic.otf
    SFCompactText-Regular.otf
    SFCompactText-RegularItalic.otf
    SFCompactText-Semibold.otf
    SFCompactText-SemiboldItalic.otf
    SFNSDisplay-BlackItalic.otf
    SFNSDisplay-BoldItalic.otf
    SFNSDisplay-HeavyItalic.otf
    SFNSDisplay-LightItalic.otf
    SFNSDisplay-MediumItalic.otf
    SFNSDisplay-RegularItalic.otf
    SFNSDisplay-SemiboldItalic.otf
    SFNSDisplay-ThinItalic.otf
    SFNSDisplay-UltralightItalic.otf
    SFNSDisplay.ttf
    SFNSDisplayCondensed-Black.otf
    SFNSDisplayCondensed-Bold.otf
    SFNSDisplayCondensed-Heavy.otf
    SFNSDisplayCondensed-Light.otf
    SFNSDisplayCondensed-Medium.otf
    SFNSDisplayCondensed-Regular.otf
    SFNSDisplayCondensed-Semibold.otf
    SFNSDisplayCondensed-Thin.otf
    SFNSDisplayCondensed-Ultralight.otf
    SFNSSymbols-Regular.otf
    SFNSText.ttf
    SFNSTextCondensed-Bold.otf
    SFNSTextCondensed-Heavy.otf
    SFNSTextCondensed-Light.otf
    SFNSTextCondensed-Medium.otf
    SFNSTextCondensed-Regular.otf
    SFNSTextCondensed-Semibold.otf
    SFNSTextItalic.ttf
    STHeiti Light.ttc
    STHeiti Medium.ttc
    Symbol.ttf
    Thonburi.ttc
    Times.ttc
    TimesLTMM
    ZapfDingbats.ttf
    ヒラギノ明朝 ProN.ttc
    ヒラギノ丸ゴ ProN W4.ttc
    ヒラギノ角ゴシック W0.ttc
    ヒラギノ角ゴシック W1.ttc
    ヒラギノ角ゴシック W2.ttc
    ヒラギノ角ゴシック W3.ttc
    ヒラギノ角ゴシック W4.ttc
    ヒラギノ角ゴシック W5.ttc
    ヒラギノ角ゴシック W6.ttc
    ヒラギノ角ゴシック W7.ttc
    ヒラギノ角ゴシック W8.ttc
    ヒラギノ角ゴシック W9.ttc
    """
}
