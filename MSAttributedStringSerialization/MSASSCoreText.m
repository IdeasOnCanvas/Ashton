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
                newAttrs[@"underlineColor"] = [self arrayForColor:(__bridge CGColorRef)(attr)];
            }
            if ([attrName isEqual:(id)kCTForegroundColorAttributeName] || [attrName isEqual:(id)kCTStrokeColorAttributeName]) {
                // produces: color
                newAttrs[@"color"] = [self arrayForColor:(__bridge CGColorRef)(attr)];
            }
            // TODO: strikethrough, strikethroughColor
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
                newAttrs[(id)kCTUnderlineColorAttributeName] = [self colorForArray:attr];
            }
            if ([attrName isEqual:@"color"]) {
                // consumes: color
                newAttrs[(id)kCTForegroundColorAttributeName] = [self colorForArray:attr];
            }
            // TODO: strikethrough, strikethroughColor
        }
        [output setAttributes:newAttrs range:range];
    }];

    return output;
}

- (NSArray *)arrayForColor:(CGColorRef)color {
    CGFloat red, green, blue;
    CGFloat alpha = CGColorGetAlpha(color);
    const CGFloat *components = CGColorGetComponents(color);
    if (CGColorGetNumberOfComponents(color) == 2) {
        red = green = blue = components[0];
    } else if (CGColorGetNumberOfComponents(color) == 4) {
        red = components[0];
        green = components[1];
        blue = components[2];
    } else {
        red = green = blue = 0;
    }
    return @[ @(red), @(green), @(blue), @(alpha) ];
}

- (id)colorForArray:(NSArray *)input {
    const CGFloat components[] = { [input[0] doubleValue], [input[1] doubleValue], [input[2] doubleValue], [input[3] doubleValue] };
    return CFBridgingRelease(CGColorCreate(CGColorSpaceCreateDeviceRGB(), components));
}

@end