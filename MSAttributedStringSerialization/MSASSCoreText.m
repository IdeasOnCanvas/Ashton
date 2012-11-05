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
        for (NSString *attrName in attrs) {
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

                // TODO: fontTraitBold, fontTraitItalic
                CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes(CFBridgingRetain(@{ (id)kCTFontNameAttribute: attrs[@"fontFamilyName"] }));
                newAttrs[(id)kCTFontAttributeName] = CFBridgingRelease(CTFontCreateWithFontDescriptor(descriptor, [attrs[@"fontPointSize"] doubleValue], NULL));
            }
            if ([attrName isEqual:@"underline"]) {
                // consumes: underline
                if ([attr isEqual:@"single"]) newAttrs[(id)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleSingle);
                if ([attr isEqual:@"thick"]) newAttrs[(id)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleThick);
                if ([attr isEqual:@"double"]) newAttrs[(id)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleDouble);
            }
            if ([attrName isEqual:@"underlineColor"]) {
                // consumes: underlineColor

                newAttrs[(id)kCTUnderlineColorAttributeName] = [self colorFromHexRGB:attr];
            }
            if ([attrName isEqual:@"color"]) {
                // consumes: color
                newAttrs[(id)kCTForegroundColorAttributeName] = [self colorFromHexRGB:attr];
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

// From http://cocoa.karelia.com/Foundation_Categories/NSColor__Instantiat.m
- (id)colorFromHexRGB:(NSString *)colorString {
    NSScanner *scanner = [NSScanner scannerWithString:colorString];
    unsigned int colorCode = 0;
    [scanner scanHexInt:&colorCode];

    unsigned char redByte, greenByte, blueByte;
	redByte   = (unsigned char) (colorCode >> 16);
	greenByte = (unsigned char) (colorCode >> 8);
	blueByte  = (unsigned char) (colorCode);	// masks off high bits

    const CGFloat components[] = { (float)redByte / 0xff, (float)greenByte / 0xff, (float)blueByte / 0xff, 1.0 };
    return CFBridgingRelease(CGColorCreate(CGColorSpaceCreateDeviceRGB(), components));
}

@end
