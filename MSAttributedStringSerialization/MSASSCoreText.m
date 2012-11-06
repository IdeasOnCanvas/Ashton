#import "MSASSCoreText.h"
#import <CoreText/CoreText.h>

@implementation MSASSCoreText

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static MSASSCoreText *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MSASSCoreText alloc] init];
    });
    return sharedInstance;
}

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input {
    NSMutableAttributedString *output = [input mutableCopy];
    NSRange totalRange = NSMakeRange (0, input.length);
    [input enumerateAttributesInRange:totalRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithCapacity:[attrs count]];
        for (id attrName in attrs) {
            id attr = attrs[attrName];
            if ([attrName isEqual:(id)kCTParagraphStyleAttributeName]) {
                // produces: kind, textAlignment
                CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)attr;
                newAttrs[@"kind"] = @"paragraph";

                CTTextAlignment alignment;
                CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment);

                if (alignment == kCTTextAlignmentLeft) newAttrs[@"textAlignment"] = @"left";
                if (alignment == kCTTextAlignmentRight) newAttrs[@"textAlignment"] = @"right";
                if (alignment == kCTTextAlignmentCenter) newAttrs[@"textAlignment"] = @"center";
            }
            if ([attrName isEqual:(id)kCTFontAttributeName]) {
                // produces: fontFamilyName, fontTraitBold, fontTraitItalic, fontPointSize
                CTFontRef font = (__bridge CTFontRef)attr;

                CTFontSymbolicTraits symbolicTraits = CTFontGetSymbolicTraits(font);
                if ((symbolicTraits & kCTFontTraitBold) == kCTFontTraitBold) newAttrs[@"fontTraitBold"] = @(YES);
                if ((symbolicTraits & kCTFontTraitItalic) == kCTFontTraitItalic) newAttrs[@"fontTraitItalic"] = @(YES);

                newAttrs[@"fontPointSize"] = @(CTFontGetSize(font));
                newAttrs[@"fontFamilyName"] = CFBridgingRelease(CTFontCopyName(font, kCTFontFamilyNameKey));
            }
            if ([attrName isEqual:(id)kCTSuperscriptAttributeName]) {
                if ([attr intValue] == 1) newAttrs[@"verticalAlign"] = @"super";
                if ([attr intValue] == -1) newAttrs[@"verticalAlign"] = @"sub";
            }
            if ([attrName isEqual:(id)kCTUnderlineStyleAttributeName]) {
                // produces: underline
                if ([attr isEqual:@(kCTUnderlineStyleSingle)]) newAttrs[@"underline"] = @"single";
                if ([attr isEqual:@(kCTUnderlineStyleThick)]) newAttrs[@"underline"] = @"thick";
                if ([attr isEqual:@(kCTUnderlineStyleDouble)]) newAttrs[@"underline"] = @"double";
            }
            if ([attrName isEqual:(id)kCTUnderlineColorAttributeName]) {
                // produces: underlineColor
                newAttrs[@"underlineColor"] = [self CSSForColor:(__bridge CGColorRef)(attr)];
            }
            if ([attrName isEqual:(id)kCTForegroundColorAttributeName] || [attrName isEqual:(id)kCTStrokeColorAttributeName]) {
                // produces: color
                newAttrs[@"color"] = [self CSSForColor:(__bridge CGColorRef)(attr)];
            }
        }
        [output setAttributes:newAttrs range:range];
    }];

    return output;
}

- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input {
    NSMutableAttributedString *output = [input mutableCopy];
    NSRange totalRange = NSMakeRange (0, input.length);
    [input enumerateAttributesInRange:totalRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithCapacity:[attrs count]];
        for (NSString *attrName in attrs) {
            id attr = attrs[attrName];
            if ([attrName isEqual:@"kind"] && [attr isEqual:@"paragraph"]) {
                // consumes: kind, textAlignment

                CTTextAlignment alignment = kCTTextAlignmentNatural;
                if ([attrs[@"textAlignment"] isEqual:@"left"]) alignment = kCTTextAlignmentLeft;
                if ([attrs[@"textAlignment"] isEqual:@"right"]) alignment = kCTTextAlignmentRight;
                if ([attrs[@"textAlignment"] isEqual:@"center"]) alignment = kCTTextAlignmentCenter;

                CTParagraphStyleSetting settings[] = {
                    { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &alignment },
                };

                newAttrs[(id)kCTParagraphStyleAttributeName] = CFBridgingRelease(CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(CTParagraphStyleSetting)));
            }
            if ([attrName isEqual:@"fontFamilyName"]) {
                // consumes: fontFamilyName, fontTraitBold, fontTraitItalic, fontPointSize

                CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes(CFBridgingRetain(@{
                                                                                                       (id)kCTFontNameAttribute: attrs[@"fontFamilyName"],
                                                                                                       }));
                CTFontRef font = CTFontCreateWithFontDescriptor(descriptor, [attrs[@"fontPointSize"] doubleValue], NULL);

                CTFontSymbolicTraits symbolicTraits = 0; // using CTFontGetSymbolicTraits also makes CTFontCreateCopyWithSymbolicTraits fail
                if ([attrs[@"fontTraitBold"] isEqual:@(YES)]) symbolicTraits = symbolicTraits | kCTFontTraitBold;
                if ([attrs[@"fontTraitItalic"] isEqual:@(YES)]) symbolicTraits = symbolicTraits | kCTFontTraitItalic;
                if (symbolicTraits != 0) {
                    // Unfortunately CTFontCreateCopyWithSymbolicTraits returns NULL when there are no symbolicTraits (== 0)
                    // Is there a better way to detect "no" symbolic traits?
                    font = CTFontCreateCopyWithSymbolicTraits(font, 0.0, NULL, symbolicTraits, symbolicTraits);
                }

                newAttrs[(id)kCTFontAttributeName] = CFBridgingRelease(font);
            }
            if ([attrName isEqual:@"verticalAlign"]) {
                if ([attr isEqual:@"super"]) newAttrs[(id)kCTSuperscriptAttributeName] = @(1);
                if ([attr isEqual:@"sub"]) newAttrs[(id)kCTSuperscriptAttributeName] = @(-1);
            }
            if ([attrName isEqual:@"underline"]) {
                // consumes: underline
                if ([attr isEqual:@"single"]) newAttrs[(id)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleSingle);
                if ([attr isEqual:@"thick"]) newAttrs[(id)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleThick);
                if ([attr isEqual:@"double"]) newAttrs[(id)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleDouble);
            }
            if ([attrName isEqual:@"underlineColor"]) {
                // consumes: underlineColor
                newAttrs[(id)kCTUnderlineColorAttributeName] = [self colorForCSS:attr];
            }
            if ([attrName isEqual:@"color"]) {
                // consumes: color
                newAttrs[(id)kCTForegroundColorAttributeName] = [self colorForCSS:attr];
            }
            if ([attrName isEqual:@"strikethrough"]) {
                // consumes: strikethrough
            }
            if ([attrName isEqual:@"strikethroughColor"]) {
                // consumes strikethroughColor
            }
        }
        [output setAttributes:newAttrs range:range];
    }];

    return output;
}

- (NSString *)CSSForColor:(CGColorRef)color {
    int red, green, blue;
    float alpha = CGColorGetAlpha(color);
    const CGFloat *components = CGColorGetComponents(color);
    if (CGColorGetNumberOfComponents(color) == 2) {
        red = green = blue = components[0] * 255;
    } else if (CGColorGetNumberOfComponents(color) == 4) {
        red = components[0] * 255;
        green = components[1] * 255;
        blue = components[2] * 255;
    } else {
        red = green = blue = 0;
    }
    return [NSString stringWithFormat:@"rgba(%i, %i, %i, %f)", red, green, blue, alpha];
}

- (id)colorForCSS:(NSString *)css {
    NSScanner *scanner = [NSScanner scannerWithString:css];
    [scanner scanString:@"rgba(" intoString:NULL];
    int red; [scanner scanInt:&red];
    [scanner scanString:@", " intoString:NULL];
    int green; [scanner scanInt:&green];
    [scanner scanString:@", " intoString:NULL];
    int blue; [scanner scanInt:&blue];
    [scanner scanString:@", " intoString:NULL];
    float alpha; [scanner scanFloat:&alpha];

    const CGFloat components[] = { (float)red / 255, (float)green / 255, (float)blue / 255, alpha };
    return CFBridgingRelease(CGColorCreate(CGColorSpaceCreateDeviceRGB(), components));
}

@end
