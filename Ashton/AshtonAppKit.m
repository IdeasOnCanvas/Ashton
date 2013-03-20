#import "AshtonAppKit.h"
#import "AshtonIntermediate.h"
#import "AshtonUtils.h"

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

                if ([paragraphStyle alignment] == NSLeftTextAlignment) attrDict[AshtonParagraphAttrTextAlignment] = @"left";
                if ([paragraphStyle alignment] == NSRightTextAlignment) attrDict[AshtonParagraphAttrTextAlignment] = @"right";
                if ([paragraphStyle alignment] == NSCenterTextAlignment) attrDict[AshtonParagraphAttrTextAlignment] = @"center";
                newAttrs[AshtonAttrParagraph] = attrDict;
            }
            if ([attrName isEqual:NSFontAttributeName]) {
                // produces: font
                NSFont *font = (NSFont *)attr;
                NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];
                NSFontDescriptor *fontDescriptor = [font fontDescriptor];
                NSFontSymbolicTraits symbolicTraits = [fontDescriptor symbolicTraits];
                if ((symbolicTraits & NSFontBoldTrait) == NSFontBoldTrait) attrDict[AshtonFontAttrTraitBold] = @(YES);
                if ((symbolicTraits & NSFontItalicTrait) == NSFontItalicTrait) attrDict[AshtonFontAttrTraitItalic] = @(YES);

                // non-default font feature settings
                NSArray *fontFeatures = [fontDescriptor objectForKey:NSFontFeatureSettingsAttribute];
                NSMutableSet *features = [NSMutableSet set];
                if (fontFeatures) {
                    for (NSDictionary *feature in fontFeatures) {
                        [features addObject:@[feature[NSFontFeatureTypeIdentifierKey], feature[NSFontFeatureSelectorIdentifierKey]]];
                    }
                }

                attrDict[AshtonFontAttrFeatures] = features;
                attrDict[AshtonFontAttrPointSize] = @(font.pointSize);
                attrDict[AshtonFontAttrFamilyName] = font.familyName;
                newAttrs[AshtonAttrFont] = attrDict;
            }
            if ([attrName isEqual:NSSuperscriptAttributeName]) {
                if ([attr intValue] == 1) newAttrs[AshtonAttrVerticalAlign] = AshtonVerticalAlignStyleSuper;
                if ([attr intValue] == -1) newAttrs[AshtonAttrVerticalAlign] = AshtonVerticalAlignStyleSub;
            }
            if ([attrName isEqual:NSUnderlineStyleAttributeName]) {
                // produces: underline
                if ([attr isEqual:@(NSUnderlineStyleSingle)]) newAttrs[AshtonAttrUnderline] = AshtonUnderlineStyleSingle;
                if ([attr isEqual:@(NSUnderlineStyleThick)]) newAttrs[AshtonAttrUnderline] = AshtonUnderlineStyleThick;
                if ([attr isEqual:@(NSUnderlineStyleDouble)]) newAttrs[AshtonAttrUnderline] = AshtonUnderlineStyleDouble;
            }
            if ([attrName isEqual:NSUnderlineColorAttributeName]) {
                // produces: underlineColor
                newAttrs[AshtonAttrUnderlineColor] = [self arrayForColor:attr];
            }
            if ([attrName isEqual:NSForegroundColorAttributeName] || [attrName isEqual:NSStrokeColorAttributeName]) {
                // produces: color
                newAttrs[AshtonAttrColor] = [self arrayForColor:attr];
            }

            if ([attrName isEqual:NSStrikethroughStyleAttributeName]) {
                // produces: strikethrough
                if ([attr isEqual:@(NSUnderlineStyleSingle)]) newAttrs[AshtonAttrStrikethrough] = AshtonStrikethroughStyleSingle;
                if ([attr isEqual:@(NSUnderlineStyleThick)]) newAttrs[AshtonAttrStrikethrough] = AshtonStrikethroughStyleThick;
                if ([attr isEqual:@(NSUnderlineStyleDouble)]) newAttrs[AshtonAttrStrikethrough] = AshtonStrikethroughStyleDouble;
            }
            if ([attrName isEqual:NSStrikethroughColorAttributeName]) {
                // produces: strikethroughColor
                newAttrs[AshtonAttrStrikethroughColor] = [self arrayForColor:attr];
            }
            if ([attrName isEqual:NSLinkAttributeName]) {
                newAttrs[AshtonAttrLink] = [attr absoluteString];
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
            if ([attrName isEqualToString:AshtonAttrParagraph]) {
                // consumes: paragraph
                NSDictionary *attrDict = attr;
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];

                if ([attrDict[AshtonParagraphAttrTextAlignment] isEqualToString:@"left"]) paragraphStyle.alignment = NSLeftTextAlignment;
                if ([attrDict[AshtonParagraphAttrTextAlignment] isEqualToString:@"right"]) paragraphStyle.alignment = NSRightTextAlignment;
                if ([attrDict[AshtonParagraphAttrTextAlignment] isEqualToString:@"center"]) paragraphStyle.alignment = NSCenterTextAlignment;

                newAttrs[NSParagraphStyleAttributeName] = [paragraphStyle copy];
            }
            if ([attrName isEqualToString:AshtonAttrFont]) {
                // consumes: font
                NSDictionary *attrDict = attr;
                NSFont *font = [AshtonUtils CTFontRefWithName:attrDict[AshtonFontAttrFamilyName]
                                                                               size:[attrDict[AshtonFontAttrPointSize] doubleValue]
                                                                          boldTrait:[attrDict[AshtonFontAttrTraitBold] isEqual:@(YES)]
                                                                        italicTrait:[attrDict[AshtonFontAttrTraitItalic] isEqual:@(YES)]
                                                                           features:attrDict[AshtonFontAttrFeatures]];
                if (font) newAttrs[NSFontAttributeName] = font;
            }
            if ([attrName isEqualToString:AshtonAttrVerticalAlign]) {
                if ([attr isEqualToString:AshtonVerticalAlignStyleSuper]) newAttrs[(id)kCTSuperscriptAttributeName] = @(1);
                if ([attr isEqualToString:AshtonVerticalAlignStyleSub]) newAttrs[(id)kCTSuperscriptAttributeName] = @(-1);
            }
            if ([attrName isEqualToString:AshtonAttrUnderline]) {
                // consumes: underline
                if ([attr isEqualToString:AshtonUnderlineStyleSingle]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                if ([attr isEqualToString:AshtonUnderlineStyleThick]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleThick);
                if ([attr isEqualToString:AshtonUnderlineStyleDouble]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleDouble);
            }
            if ([attrName isEqualToString:AshtonAttrUnderlineColor]) {
                // consumes: underlineColor
                newAttrs[NSUnderlineColorAttributeName] = [self colorForArray:attr];
            }
            if ([attrName isEqualToString:AshtonAttrColor]) {
                // consumes: color
                newAttrs[NSForegroundColorAttributeName] = [self colorForArray:attr];
            }
            if ([attrName isEqualToString:AshtonAttrStrikethrough]) {
                // consumes: strikethrough
                if ([attr isEqualToString:AshtonStrikethroughStyleSingle]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
                if ([attr isEqualToString:AshtonStrikethroughStyleThick]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleThick);
                if ([attr isEqualToString:AshtonStrikethroughStyleDouble]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleDouble);
            }
            if ([attrName isEqualToString:AshtonAttrStrikethroughColor]) {
                // consumes strikethroughColor
                newAttrs[NSStrikethroughColorAttributeName] = [self colorForArray:attr];
            }
            if ([attrName isEqualToString:AshtonAttrLink]) {
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
