#import "AshtonCoreText.h"
#import <CoreText/CoreText.h>

@implementation AshtonCoreText

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static AshtonCoreText *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AshtonCoreText alloc] init];
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
                // produces: paragraph
                CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)attr;
                NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];

                CTTextAlignment alignment;
                CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment);

                if (alignment == kCTTextAlignmentLeft) attrDict[@"textAlignment"] = @"left";
                if (alignment == kCTTextAlignmentRight) attrDict[@"textAlignment"] = @"right";
                if (alignment == kCTTextAlignmentCenter) attrDict[@"textAlignment"] = @"center";
                newAttrs[@"paragraph"] = attrDict;
            }
            if ([attrName isEqual:(id)kCTFontAttributeName]) {
                // produces: font
                CTFontRef font = (__bridge CTFontRef)attr;
                NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];

                CTFontSymbolicTraits symbolicTraits = CTFontGetSymbolicTraits(font);
                if ((symbolicTraits & kCTFontTraitBold) == kCTFontTraitBold) attrDict[@"traitBold"] = @(YES);
                if ((symbolicTraits & kCTFontTraitItalic) == kCTFontTraitItalic) attrDict[@"traitItalic"] = @(YES);

                attrDict[@"pointSize"] = @(CTFontGetSize(font));
                attrDict[@"familyName"] = CFBridgingRelease(CTFontCopyName(font, kCTFontFamilyNameKey));
                newAttrs[@"font"] = attrDict;
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
            if ([attrName isEqual:@"paragraph"]) {
                // consumes: paragraph
                NSDictionary *attrDict = attr;
                CTTextAlignment alignment = kCTTextAlignmentNatural;
                if ([attrDict[@"textAlignment"] isEqual:@"left"]) alignment = kCTTextAlignmentLeft;
                if ([attrDict[@"textAlignment"] isEqual:@"right"]) alignment = kCTTextAlignmentRight;
                if ([attrDict[@"textAlignment"] isEqual:@"center"]) alignment = kCTTextAlignmentCenter;

                CTParagraphStyleSetting settings[] = {
                    { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &alignment },
                };

                newAttrs[(id)kCTParagraphStyleAttributeName] = CFBridgingRelease(CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(CTParagraphStyleSetting)));
            }
            if ([attrName isEqual:@"font"]) {
                // consumes: font
                NSDictionary *attrDict = attr;
                CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes(CFBridgingRetain(@{
                                                                                                       (id)kCTFontNameAttribute: attrDict[@"familyName"],
                                                                                                       }));
                CTFontRef font = CTFontCreateWithFontDescriptor(descriptor, [attrDict[@"pointSize"] doubleValue], NULL);

                CTFontSymbolicTraits symbolicTraits = 0; // using CTFontGetSymbolicTraits also makes CTFontCreateCopyWithSymbolicTraits fail
                if ([attrDict[@"traitBold"] isEqual:@(YES)]) symbolicTraits = symbolicTraits | kCTFontTraitBold;
                if ([attrDict[@"traitItalic"] isEqual:@(YES)]) symbolicTraits = symbolicTraits | kCTFontTraitItalic;
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