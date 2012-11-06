#import "MSASSAppKit.h"

@implementation MSASSAppKit

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static MSASSAppKit *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MSASSAppKit alloc] init];
    });
    return sharedInstance;
}

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input {
    NSMutableAttributedString *output = [input mutableCopy];
    NSRange totalRange = NSMakeRange (0, input.length);
    [input enumerateAttributesInRange:totalRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithCapacity:[attrs count]];
        for (NSString *attrName in attrs) {
            id attr = attrs[attrName];
            if ([attrName isEqual:NSParagraphStyleAttributeName]) {
                // produces: kind, textAlignment
                NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)attr;
                newAttrs[@"kind"] = @"paragraph";

                if ([paragraphStyle alignment] == NSLeftTextAlignment) newAttrs[@"textAlignment"] = @"left";
                if ([paragraphStyle alignment] == NSRightTextAlignment) newAttrs[@"textAlignment"] = @"right";
                if ([paragraphStyle alignment] == NSCenterTextAlignment) newAttrs[@"textAlignment"] = @"center";
            }
            if ([attrName isEqual:NSFontAttributeName]) {
                // produces: fontFamilyName, fontTraitBold, fontTraitItalic, fontPointSize
                NSFont *font = (NSFont *)attr;
                NSFontSymbolicTraits symbolicTraits = [[font fontDescriptor] symbolicTraits];
                if ((symbolicTraits & NSFontBoldTrait) == NSFontBoldTrait) newAttrs[@"fontTraitBold"] = @(YES);
                if ((symbolicTraits & NSFontItalicTrait) == NSFontItalicTrait) newAttrs[@"fontTraitItalic"] = @(YES);

                newAttrs[@"fontPointSize"] = @(font.pointSize);
                newAttrs[@"fontFamilyName"] = font.familyName;
            }
            if ([attrName isEqual:NSSuperscriptAttributeName]) {
                if ([attr intValue] == 1) newAttrs[@"verticalAlign"] = @"super";
                if ([attr intValue] == -1) newAttrs[@"verticalAlign"] = @"sub";
            }
            if ([attrName isEqual:NSUnderlineStyleAttributeName]) {
                // produces: underline
                if ([attr isEqual:@(NSUnderlineStyleSingle)]) newAttrs[@"underline"] = @"single";
                if ([attr isEqual:@(NSUnderlineStyleThick)]) newAttrs[@"underline"] = @"thick";
                if ([attr isEqual:@(NSUnderlineStyleDouble)]) newAttrs[@"underline"] = @"double";
            }
            if ([attrName isEqual:NSUnderlineColorAttributeName]) {
                // produces: underlineColor
                newAttrs[@"underlineColor"] = [self arrayForColor:attr];
            }
            if ([attrName isEqual:NSForegroundColorAttributeName] || [attrName isEqual:NSStrokeColorAttributeName]) {
                // produces: color
                newAttrs[@"color"] = [self arrayForColor:attr];
            }

            if ([attrName isEqual:NSStrikethroughStyleAttributeName]) {
                // produces: strikethrough
                if ([attr isEqual:@(NSUnderlineStyleSingle)]) newAttrs[@"strikethrough"] = @"single";
                if ([attr isEqual:@(NSUnderlineStyleThick)]) newAttrs[@"strikethrough"] = @"thick";
                if ([attr isEqual:@(NSUnderlineStyleDouble)]) newAttrs[@"strikethrough"] = @"double";
            }
            if ([attrName isEqual:NSStrikethroughColorAttributeName]) {
                // produces: strikethroughColor
                newAttrs[@"strikethroughColor"] = [self arrayForColor:attr];
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
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];

                if ([attrs[@"textAlignment"] isEqual:@"left"]) paragraphStyle.alignment = NSLeftTextAlignment;
                if ([attrs[@"textAlignment"] isEqual:@"right"]) paragraphStyle.alignment = NSRightTextAlignment;
                if ([attrs[@"textAlignment"] isEqual:@"center"]) paragraphStyle.alignment = NSCenterTextAlignment;

                newAttrs[NSParagraphStyleAttributeName] = [paragraphStyle copy];
            }
            if ([attrName isEqual:@"fontFamilyName"]) {
                // consumes: fontFamilyName, fontTraitBold, fontTraitItalic, fontPointSize

                NSFontDescriptor *fontDescriptor = [NSFontDescriptor fontDescriptorWithFontAttributes:@{ NSFontFamilyAttribute: attrs[@"fontFamilyName"] }];
                NSFontSymbolicTraits symbolicTraits = [fontDescriptor symbolicTraits];
                if ([attrs[@"fontTraitBold"] isEqual:@(YES)]) symbolicTraits = symbolicTraits | NSFontBoldTrait;
                if ([attrs[@"fontTraitItalic"] isEqual:@(YES)]) symbolicTraits = symbolicTraits | NSFontItalicTrait;
                fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];

                newAttrs[NSFontAttributeName] = [NSFont fontWithDescriptor:fontDescriptor size:[attrs[@"fontPointSize"] doubleValue]];
            }
            if ([attrName isEqual:@"verticalAlign"]) {
                if ([attr isEqual:@"super"]) newAttrs[(id)kCTSuperscriptAttributeName] = @(1);
                if ([attr isEqual:@"sub"]) newAttrs[(id)kCTSuperscriptAttributeName] = @(-1);
            }
            if ([attrName isEqual:@"underline"]) {
                // consumes: underline
                if ([attr isEqual:@"single"]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                if ([attr isEqual:@"thick"]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleThick);
                if ([attr isEqual:@"double"]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleDouble);
            }
            if ([attrName isEqual:@"underlineColor"]) {
                // consumes: underlineColor
                newAttrs[NSUnderlineColorAttributeName] = [self colorForArray:attr];
            }
            if ([attrName isEqual:@"color"]) {
                // consumes: color
                newAttrs[NSForegroundColorAttributeName] = [self colorForArray:attr];
            }
            if ([attrName isEqual:@"strikethrough"]) {
                // consumes: strikethrough
                if ([attr isEqual:@"single"]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
                if ([attr isEqual:@"thick"]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleThick);
                if ([attr isEqual:@"double"]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleDouble);
            }
            if ([attrName isEqual:@"strikethroughColor"]) {
                // consumes strikethroughColor
                newAttrs[NSStrikethroughColorAttributeName] = [self colorForArray:attr];
            }
        }
        [output setAttributes:newAttrs range:range];
    }];

    return output;
}


- (NSArray *)arrayForColor:(NSColor *)color {
    CGFloat red, green, blue;
    CGFloat alpha = color.alphaComponent;
    if ([color.colorSpaceName isEqual:NSCalibratedWhiteColorSpace]) {
        red = green = blue = color.whiteComponent;
    } else if ([color.colorSpaceName isEqual:NSCalibratedRGBColorSpace] ||
               [color.colorSpaceName isEqual:NSDeviceRGBColorSpace]) {
        red = color.redComponent;
        green = color.greenComponent;
        blue = color.blueComponent;
    } else {
        red = green = blue = 0;
    }
    return @[ @(red), @(green), @(blue), @(alpha) ];
}

- (NSColor *)colorForArray:(NSArray *)input {
	return [NSColor colorWithCalibratedRed:[input[0] doubleValue] green:[input[1] doubleValue] blue:[input[2] doubleValue] alpha:[input[3] doubleValue]];
}

@end
