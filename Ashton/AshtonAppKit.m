#import "AshtonAppKit.h"

@implementation AshtonAppKit

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AshtonAppKit *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AshtonAppKit alloc] init];
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
                // produces: paragraph
                NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)attr;
                NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];

                if ([paragraphStyle alignment] == NSLeftTextAlignment) attrDict[@"textAlignment"] = @"left";
                if ([paragraphStyle alignment] == NSRightTextAlignment) attrDict[@"textAlignment"] = @"right";
                if ([paragraphStyle alignment] == NSCenterTextAlignment) attrDict[@"textAlignment"] = @"center";
                newAttrs[@"paragraph"] = attrDict;
            }
            if ([attrName isEqual:NSFontAttributeName]) {
                // produces: font
                NSFont *font = (NSFont *)attr;
                NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];
                NSFontDescriptor *fontDescriptor = [font fontDescriptor];
                NSFontSymbolicTraits symbolicTraits = [fontDescriptor symbolicTraits];
                if ((symbolicTraits & NSFontBoldTrait) == NSFontBoldTrait) attrDict[@"traitBold"] = @(YES);
                if ((symbolicTraits & NSFontItalicTrait) == NSFontItalicTrait) attrDict[@"traitItalic"] = @(YES);

                // non-default font feature settings
                NSArray *fontFeatures = [fontDescriptor objectForKey:NSFontFeatureSettingsAttribute];
                NSMutableSet *features = [NSMutableSet set];
                if (fontFeatures) {
                    for (NSDictionary *feature in fontFeatures) {
                        [features addObject:@[feature[NSFontFeatureTypeIdentifierKey], feature[NSFontFeatureSelectorIdentifierKey]]];
                    }
                }

                attrDict[@"features"] = features;
                attrDict[@"pointSize"] = @(font.pointSize);
                attrDict[@"familyName"] = font.familyName;
                newAttrs[@"font"] = attrDict;
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
            if ([attrName isEqual:NSLinkAttributeName]) {
                newAttrs[@"link"] = [attr absoluteString];
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
            if ([attrName isEqual:@"paragraph"]) {
                // consumes: paragraph
                NSDictionary *attrDict = attr;
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];

                if ([attrDict[@"textAlignment"] isEqual:@"left"]) paragraphStyle.alignment = NSLeftTextAlignment;
                if ([attrDict[@"textAlignment"] isEqual:@"right"]) paragraphStyle.alignment = NSRightTextAlignment;
                if ([attrDict[@"textAlignment"] isEqual:@"center"]) paragraphStyle.alignment = NSCenterTextAlignment;

                newAttrs[NSParagraphStyleAttributeName] = [paragraphStyle copy];
            }
            if ([attrName isEqual:@"font"]) {
                // consumes: font
                NSDictionary *attrDict = attr;
                NSFontDescriptor *fontDescriptor = [NSFontDescriptor fontDescriptorWithFontAttributes:@{ NSFontFamilyAttribute: attrDict[@"familyName"] }];
                NSFontSymbolicTraits symbolicTraits = [fontDescriptor symbolicTraits];
                if ([attrDict[@"traitBold"] isEqual:@(YES)]) symbolicTraits = symbolicTraits | NSFontBoldTrait;
                if ([attrDict[@"traitItalic"] isEqual:@(YES)]) symbolicTraits = symbolicTraits | NSFontItalicTrait;
                fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];

                NSSet *features = attrDict[@"features"];
                if (features) {
                    NSMutableArray *fontFeatures = [NSMutableArray array];
                    for (NSArray *feature in features) {
                        [fontFeatures addObject:@{NSFontFeatureTypeIdentifierKey: feature[0], NSFontFeatureSelectorIdentifierKey: feature[1]}];
                    }
                    fontDescriptor = [fontDescriptor fontDescriptorByAddingAttributes:@{ NSFontFeatureSettingsAttribute: fontFeatures }];
                }

                newAttrs[NSFontAttributeName] = [NSFont fontWithDescriptor:fontDescriptor size:[attrDict[@"pointSize"] doubleValue]];
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
            if ([attrName isEqual:@"link"]) {
                newAttrs[NSLinkAttributeName] = [NSURL URLWithString:attr];
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
