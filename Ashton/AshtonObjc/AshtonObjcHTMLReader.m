//
//  AshtonObjcHTMLReader.m
//  Ashton
//
//  Created by Michael Schwarz on 20.12.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

#import "AshtonObjcHTMLReader.h"
#import "TBXML.h"
#import "AshtonEnvironment.h"
#import <CoreText/CoreText.h>


@interface AshtonObjcHTMLReader()

@property (nonatomic, strong) NSMutableAttributedString *output;
@property (nonatomic, strong) NSMutableDictionary *currentAttributes;

@end


@implementation AshtonObjcHTMLReader

+ (NSMutableDictionary *)stylesCache
{
    static NSMutableDictionary *stylesCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stylesCache = [NSMutableDictionary dictionary];
    });
    return stylesCache;
}

+ (NSMutableDictionary *)fontsCache
{
    static NSMutableDictionary *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary new];
    });
    return cache;
}

- (NSAttributedString *)decodeAttributedStringFromHTML:(NSString *)html
{
    if (html == nil || html.length == 0) { return nil; }
    
    self.output = [NSMutableAttributedString new];
    self.currentAttributes = [NSMutableDictionary new];
    NSMutableString *stringToParse = [[NSMutableString alloc] initWithFormat:@"<html>%@</html>", html];
    NSError *parseError;
    TBXML *tbxml = [[TBXML alloc] initWithXMLString:stringToParse error:&parseError];
    if (parseError != nil) {
        NSLog(@"%@", parseError.description);
        return nil;
    }
    [self parseElement:tbxml.rootXMLElement];
    return self.output;
}

- (void)parseElement:(TBXMLElement *)element
{
    NSDictionary *attributesBeforeElement = self.currentAttributes.copy;
    TBXMLAttribute *attribute = element->firstAttribute;
    if (attribute != nil) {
        [self parseAttribute:attribute];
    }

    NSString *currentElementName = [TBXML elementName:element];
    [self parseStyleFromElementName:currentElementName];

    NSString *text = [TBXML textForElement:element];
    if (text != nil) {
        [self appendString:[self convertHTMLEntities:text]];
    }

    TBXMLElement *firstChild = element->firstChild;
    if (firstChild != nil) {
        [self parseElement:firstChild];
    }

    TBXMLElement *nextSibling = element->nextSibling;
    if (nextSibling != nil) {
        if ([currentElementName isEqualToString:@"p"]) {
            [self appendString:@"\n"];
        }

        self.currentAttributes = [attributesBeforeElement mutableCopy];
        [self parseElement:nextSibling];
    }
}

- (void)appendString:(NSString *)string
{
    NSAttributedString *stringToAppend;
    if (self.currentAttributes.count == 0) {
        stringToAppend = [[NSAttributedString alloc] initWithString:string];
    } else {
        stringToAppend = [[NSAttributedString alloc] initWithString:string attributes:self.currentAttributes];
    }
    [self.output appendAttributedString:stringToAppend];
}

- (void)parseStyleFromElementName:(NSString *)elementName
{
    if ([elementName isEqualToString:@"strong"]) {
        // TODO: Change for a injected default font
        ASHFont *currentFont = self.currentAttributes[NSFontAttributeName] ?: [ASHFont systemFontOfSize:12.0];
        ASHFontDescriptor *fontDescriptor = [currentFont fontDescriptor];
        CTFontSymbolicTraits traits = (CTFontSymbolicTraits)fontDescriptor.symbolicTraits;
        traits |= kCTFontBoldTrait;
        CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits((__bridge CTFontRef)currentFont, 0.0, NULL, traits, traits);
        self.currentAttributes[NSFontAttributeName] = (__bridge ASHFont *)newFont;
    }
}


- (void)parseAttribute:(TBXMLAttribute *)attribute
{
    NSString *name = [[NSString alloc] initWithCString:attribute->name encoding:NSUTF8StringEncoding];
    NSString *value = [[NSString alloc] initWithCString:attribute->value encoding:NSUTF8StringEncoding];

    if ([name isEqualToString:@"style"]) {
        [self parseStyleString:value];
    } else if ([name isEqualToString:@"href"]) {
        [self parseLink:value];
    }

    TBXMLAttribute *nextAttribute = attribute->next;
    if (nextAttribute != nil) {
        [self parseAttribute:nextAttribute];
    }
}

- (void)parseStyleString:(NSString *)styleString
{
    if (styleString == nil || styleString.length == 0) { return; }

    NSDictionary *cachedAttributes = [AshtonObjcHTMLReader stylesCache][styleString];
    if (cachedAttributes != nil) {
        [self.currentAttributes addEntriesFromDictionary:cachedAttributes];
        return;
    }

    NSMutableDictionary *attributes = [NSMutableDictionary new];
    NSScanner *scanner = [[NSScanner alloc] initWithString:styleString];
    NSString *propertyName = nil;
    NSString *value = nil;

    // font properties
    NSString *fontFamily = nil;
    NSString *postScriptname = nil;
    NSMutableArray *cocoaFontFeatures = nil;
    BOOL isBold = NO;
    BOOL isItalic = NO;
    int pointSize = 0;

    NSCharacterSet *charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@": ;"];
    [scanner setCharactersToBeSkipped:charactersToBeSkipped];

    while ([scanner scanUpToString:@":" intoString:&propertyName] && [scanner scanUpToString:@";" intoString:&value]) {
        if ([propertyName isEqualToString:@"background-color"]) {
            ASHColor *color = [self parseCSSColor:value];
            if (color == nil) { continue; }

            attributes[NSBackgroundColorAttributeName] = color;
        } else if ([propertyName isEqualToString:@"color"]) {
            ASHColor *color = [self parseCSSColor:value];
            if (color == nil) { continue; }

            attributes[NSForegroundColorAttributeName] = color;
        } else if ([propertyName isEqualToString:@"-cocoa-strikethrough-color"]) {
            ASHColor *color = [self parseCSSColor:value];
            if (color == nil) { continue; }

            attributes[NSStrikethroughColorAttributeName] = color;
        } else if ([propertyName isEqualToString:@"-cocoa-underline-color"]) {
            ASHColor *color = [self parseCSSColor:value];
            if (color == nil) { continue; }

            attributes[NSUnderlineColorAttributeName] = color;
        } else if ([propertyName isEqualToString:@"text-decoration"]) {
            static NSDictionary *textDecoration = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                textDecoration = @{
                                   @"underline": NSUnderlineStyleAttributeName,
                                   @"line-through": NSStrikethroughStyleAttributeName
                                   };
            });
            NSString *textDecorationStyle = textDecoration[value];
            if (textDecorationStyle == nil) { continue; }

            attributes[textDecorationStyle] = @(NSUnderlineStyleSingle);
        } else if ([propertyName isEqualToString:@"-cocoa-underline"] || ([propertyName isEqualToString:@"-cocoa-strikethrough"])) {
            static NSDictionary* underlineMapping = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                underlineMapping = @{
                                     @"single": @(NSUnderlineStyleSingle),
                                     @"double": @(NSUnderlineStyleDouble),
                                     @"thick": @(NSUnderlineStyleThick)
                                     };
            });
            NSNumber *style = underlineMapping[value];
            if (style == nil) { continue; }

            if ([propertyName isEqualToString:@"-cocoa-underline"]) {
                attributes[NSUnderlineStyleAttributeName] = style;
            } else {
                attributes[NSStrikethroughStyleAttributeName] = style;
            }
        } else if ([propertyName isEqualToString:@"font"]) {
            NSCharacterSet *skippedCharacters = [NSCharacterSet characterSetWithCharactersInString:@", "];
            NSScanner *scanner = [NSScanner scannerWithString:value];
            [scanner setCharactersToBeSkipped:skippedCharacters];

            isBold = [scanner scanString:@"bold" intoString:nil];
            isItalic = [scanner scanString:@"italic" intoString:nil];

            if ([scanner scanInt:&pointSize] == NO) { continue; }

            [scanner scanString:@"px" intoString:nil];
            [scanner scanString:@"\"" intoString:nil];

            if ([scanner scanUpToString:@"\"" intoString:&fontFamily] == NO) { continue; }
        } else if ([propertyName isEqualToString:@"-cocoa-font-postscriptname"]) {
            NSScanner *scanner = [NSScanner scannerWithString:value];
            [scanner scanString:@"\"" intoString:nil];
            if ([scanner scanUpToString:@"\"" intoString:&postScriptname] == NO) { continue; }

        } else if ([propertyName isEqualToString:@"text-align"]) {
            static NSDictionary* textAlignMapping = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                textAlignMapping = @{
                                     @"left": @(NSTextAlignmentLeft),
                                     @"center": @(NSTextAlignmentCenter),
                                     @"right": @(NSTextAlignmentRight),
                                     @"justify": @(NSTextAlignmentJustified)
                                     };
            });
            NSNumber *alignment = textAlignMapping[value];
            if (alignment == nil) { continue; }

            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.alignment = alignment.integerValue;
            attributes[NSParagraphStyleAttributeName] = paragraphStyle;
        } else if ([propertyName isEqualToString:@"-cocoa-baseline-offset"]) {
            attributes[NSBaselineOffsetAttributeName] = @(value.floatValue);
        } else if ([propertyName isEqualToString:@"-cocoa-vertical-align"]) {
            attributes[@"NSSuperScript"] = @(value.floatValue);
        } else if ([propertyName isEqualToString:@"vertical-align"]) {
            // skip, if we assigned already via -cocoa-vertical-align
            if (attributes[@"NSSuperScript"] != nil) { continue; }

            if ([value isEqualToString:@"super"]) {
                attributes[@"NSSuperScript"] = @(1);
            } else if ([value isEqualToString:@"sub"]) {
                attributes[@"NSSuperScript"] = @(-1);
            }
        } else if ([propertyName isEqualToString:@"-cocoa-font-features"]) {
            NSArray<NSString *> *features = [value componentsSeparatedByString:@" "];
            for (NSString *feature in features) {
                NSArray<NSString *> *featureIDs = [feature componentsSeparatedByString:@"/"];
                if (featureIDs.count != 2) { continue; }

                if (cocoaFontFeatures == nil) {
                    cocoaFontFeatures = [NSMutableArray new];
                }
                [cocoaFontFeatures addObject:@{
                                               (id)kCTFontFeatureTypeIdentifierKey: @(featureIDs[0].integerValue),
                                               (id)kCTFontFeatureSelectorIdentifierKey: @(featureIDs[1].integerValue)
                                               }];
            }
        }
    }

    if ((fontFamily != nil || postScriptname != nil) && pointSize > 0) {
        NSMutableDictionary *fontCache = [AshtonObjcHTMLReader fontsCache];
        NSString *fontName = postScriptname != nil ? postScriptname : fontFamily;

        NSMutableDictionary *descriptorAttributes = [NSMutableDictionary dictionaryWithCapacity:3];
        descriptorAttributes[(id)kCTFontSizeAttribute] = @(pointSize);
        descriptorAttributes[(id)kCTFontNameAttribute] = fontName;
        if (cocoaFontFeatures != nil) {
            descriptorAttributes[(id)kCTFontFeatureSettingsAttribute] = cocoaFontFeatures;
        }

        id font = fontCache[descriptorAttributes];

        if (font == nil) {
            CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)(descriptorAttributes));

            font = CFBridgingRelease(CTFontCreateWithFontDescriptor(descriptor, pointSize, NULL));
            CFRelease(descriptor);

            fontCache[descriptorAttributes] = font;
        }

        // We ignore symbolic traits when a postScriptName is given, because the postScriptName already encodes bold/italic and if we
        // specify it again as a trait we get different fonts (e.g. Helvetica-Oblique becomes Helvetica-LightOblique)
        if (postScriptname == nil) {
            CTFontSymbolicTraits symbolicTraits = 0;
            if (isBold) { symbolicTraits |= kCTFontTraitBold; }
            if (isItalic) { symbolicTraits |= kCTFontTraitItalic; }

            if (symbolicTraits != 0) {
                // Unfortunately CTFontCreateCopyWithSymbolicTraits returns NULL when there are no symbolicTraits (== 0)
                // Is there a better way to detect "no" symbolic traits?
                CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits((__bridge CTFontRef)font, 0.0, NULL, symbolicTraits, symbolicTraits);
                // And even worse, if a font is defined to be "only" bold (like Arial Rounded MT Bold is) then
                // CTFontCreateCopyWithSymbolicTraits also returns NULL
                if (newFont != NULL) {
                    font = CFBridgingRelease(newFont);
                }
            }
        }
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
        NSFontDescriptor *fontDescriptor = [font fontDescriptor];
        font = [ASHFont fontWithDescriptor:fontDescriptor size:fontDescriptor.pointSize];
#endif
        attributes[NSFontAttributeName] = font;
    }

    [self.currentAttributes addEntriesFromDictionary:attributes];
    [AshtonObjcHTMLReader stylesCache][styleString] = attributes;
}

- (void)parseLink:(NSString *)link
{
    if (link == nil) { return; }

    [self.currentAttributes setObject:[self convertHTMLEntities:link] forKey:NSLinkAttributeName];
}

- (NSString *)convertHTMLEntities:(NSString *)string
{
    if ([string containsString:@"&"] == NO) { return string; }

    string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    string = [string stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    string = [string stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    string = [string stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    string = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    string = [string stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n<br />"];
    
    return string;
}

- (ASHColor *)parseCSSColor:(NSString *)colorString
{
    if (colorString == nil) { return nil; }

    NSCharacterSet *skippedCharacters = [NSCharacterSet characterSetWithCharactersInString:@", "];
    NSScanner *scanner = [NSScanner scannerWithString:colorString];
    [scanner setCharactersToBeSkipped:skippedCharacters];
    int r, g, b;
    float alpha;
    if ([scanner scanString:@"rgba(" intoString:nil] == NO) { return nil; }
    if ([scanner scanInt:&r] == NO) { return nil; }
    if ([scanner scanInt:&g] == NO) { return nil; }
    if ([scanner scanInt:&b] == NO) { return nil; }
    if ([scanner scanFloat:&alpha] == NO) { return nil; }

    #ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
    return [NSColor colorWithCalibratedRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:alpha];
    #else
        return [ASHColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:alpha];
    #endif
}


@end
