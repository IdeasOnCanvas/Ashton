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
                if (![attr isKindOfClass:[NSParagraphStyle class]]) continue;
                NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)attr;
                NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];

                if ([paragraphStyle alignment] == NSLeftTextAlignment) attrDict[AshtonParagraphAttrTextAlignment] = @"left";
                if ([paragraphStyle alignment] == NSRightTextAlignment) attrDict[AshtonParagraphAttrTextAlignment] = @"right";
                if ([paragraphStyle alignment] == NSCenterTextAlignment) attrDict[AshtonParagraphAttrTextAlignment] = @"center";
                if ([paragraphStyle alignment] == NSJustifiedTextAlignment) attrDict[AshtonParagraphAttrTextAlignment] = @"justified";

                newAttrs[AshtonAttrParagraph] = attrDict;
            }
            if ([attrName isEqual:NSFontAttributeName]) {
                // produces: font
                if (![attr isKindOfClass:[NSFont class]]) continue;
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
                attrDict[AshtonFontAttrPostScriptName] = font.fontName;
                newAttrs[AshtonAttrFont] = attrDict;
            }
            if ([attrName isEqual:NSSuperscriptAttributeName]) {
                if (![attr isKindOfClass:[NSNumber class]]) continue;
                newAttrs[AshtonAttrVerticalAlign] = @([attr integerValue]);
            }
            if ([attrName isEqual:NSBaselineOffsetAttributeName]) {
                newAttrs[AshtonAttrBaselineOffset] = @([attr floatValue]);
            }
            if ([attrName isEqual:NSUnderlineStyleAttributeName]) {
                // produces: underline
                if (![attr isKindOfClass:[NSNumber class]]) continue;
                if ([attr isEqual:@(NSUnderlineStyleSingle)]) newAttrs[AshtonAttrUnderline] = AshtonUnderlineStyleSingle;
                if ([attr isEqual:@(NSUnderlineStyleThick)]) newAttrs[AshtonAttrUnderline] = AshtonUnderlineStyleThick;
                if ([attr isEqual:@(NSUnderlineStyleDouble)]) newAttrs[AshtonAttrUnderline] = AshtonUnderlineStyleDouble;
            }
            if ([attrName isEqual:NSUnderlineColorAttributeName]) {
                // produces: underlineColor
                if (![attr isKindOfClass:[NSColor class]]) continue;
                newAttrs[AshtonAttrUnderlineColor] = [self arrayForColor:attr];
            }
            if ([attrName isEqual:NSForegroundColorAttributeName] || [attrName isEqual:NSStrokeColorAttributeName]) {
                // produces: color
                if (![attr isKindOfClass:[NSColor class]]) continue;
                newAttrs[AshtonAttrColor] = [self arrayForColor:attr];
            }
            if ([attrName isEqual:NSBackgroundColorAttributeName]) {
                // produces: backgroundColor
                if (![attr isKindOfClass:[NSColor class]]) continue;
                newAttrs[AshtonAttrBackgroundColor] = [self arrayForColor:attr];
            }

            if ([attrName isEqual:NSStrikethroughStyleAttributeName]) {
                // produces: strikethrough
                if (![attr isKindOfClass:[NSNumber class]]) continue;
                if ([attr isEqual:@(NSUnderlineStyleSingle)]) newAttrs[AshtonAttrStrikethrough] = AshtonStrikethroughStyleSingle;
                if ([attr isEqual:@(NSUnderlineStyleThick)]) newAttrs[AshtonAttrStrikethrough] = AshtonStrikethroughStyleThick;
                if ([attr isEqual:@(NSUnderlineStyleDouble)]) newAttrs[AshtonAttrStrikethrough] = AshtonStrikethroughStyleDouble;
            }
            if ([attrName isEqual:NSStrikethroughColorAttributeName]) {
                // produces: strikethroughColor
                if (![attr isKindOfClass:[NSColor class]]) continue;
                newAttrs[AshtonAttrStrikethroughColor] = [self arrayForColor:attr];
            }
            if ([attrName isEqual:NSLinkAttributeName]) {
				if ([attr isKindOfClass:[NSURL class]]) {
					newAttrs[AshtonAttrLink] = [attr absoluteString];
				} else if ([attr isKindOfClass:[NSString class]]) {
					newAttrs[AshtonAttrLink] = attr;
				}
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
                if ([attrDict[AshtonParagraphAttrTextAlignment] isEqualToString:@"justified"]) paragraphStyle.alignment = NSJustifiedTextAlignment;

                newAttrs[NSParagraphStyleAttributeName] = [paragraphStyle copy];
            }
            if ([attrName isEqualToString:AshtonAttrFont]) {
                // consumes: font
                NSDictionary *attrDict = attr;
                NSFont *font = [AshtonUtils CTFontRefWithFamilyName:attrDict[AshtonFontAttrFamilyName]
                                                     postScriptName:attrDict[AshtonFontAttrPostScriptName]
                                                               size:[attrDict[AshtonFontAttrPointSize] doubleValue]
                                                          boldTrait:[attrDict[AshtonFontAttrTraitBold] isEqual:@(YES)]
                                                        italicTrait:[attrDict[AshtonFontAttrTraitItalic] isEqual:@(YES)]
                                                           features:attrDict[AshtonFontAttrFeatures]];
                if (font) {
					newAttrs[NSFontAttributeName] = font;
				} else {
					// If the font is not available on this device (e.g. custom font) fallback to system font
					newAttrs[NSFontAttributeName] = [NSFont systemFontOfSize:[attrDict[AshtonFontAttrPointSize] doubleValue]];
				}
				
            }
            if ([attrName isEqualToString:AshtonAttrVerticalAlign]) {
                newAttrs[NSSuperscriptAttributeName] = attr;
            }
            if ([attrName isEqualToString:AshtonAttrBaselineOffset]) {
                newAttrs[NSBaselineOffsetAttributeName] = attr;
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
            if ([attrName isEqualToString:AshtonAttrBackgroundColor]) {
                // consumes: backgroundColor
                newAttrs[NSBackgroundColorAttributeName] = [self colorForArray:attr];
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
                NSURL *URL = [NSURL URLWithString:attr];
				if (URL) {
					newAttrs[NSLinkAttributeName] = URL;
				}
            }
        }
        [output setAttributes:newAttrs range:range];
    }];

    return output;
}


- (NSArray *)arrayForColor:(NSColor *)color {
    NSColor *canonicalColor = [color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];

	if (!canonicalColor) {
        // We got a color with an image pattern (e.g. windowBackgroundColor) that can't be converted to RGB.
        // So we convert it to image and extract the first px.
        // The result won't be 100% correct, but better than a completely undefined color.
        NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:1 pixelsHigh:1 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:4 bitsPerPixel:32];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapRep];

        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:context];
        [color setFill];
        NSRectFill(CGRectMake(0, 0, 1, 1));
        [context flushGraphics];
        [NSGraphicsContext restoreGraphicsState];
        canonicalColor = [bitmapRep colorAtX:0 y:0];
    }

    return @[ @(canonicalColor.redComponent), @(canonicalColor.greenComponent), @(canonicalColor.blueComponent), @(canonicalColor.alphaComponent) ];
}

- (NSColor *)colorForArray:(NSArray *)input {
	return [NSColor colorWithCalibratedRed:[input[0] doubleValue] green:[input[1] doubleValue] blue:[input[2] doubleValue] alpha:[input[3] doubleValue]];
}

@end
