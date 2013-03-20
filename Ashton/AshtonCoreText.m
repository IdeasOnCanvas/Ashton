#import "AshtonCoreText.h"
#import "AshtonIntermediate.h"
#import "AshtonUtils.h"
#import <CoreText/CoreText.h>

@interface AshtonCoreText ()
@property (nonatomic, readonly) NSArray *attributesToPreserve;
@end

@implementation AshtonCoreText

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AshtonCoreText *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AshtonCoreText alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        _attributesToPreserve = @[ AshtonAttrStrikethrough, AshtonAttrStrikethroughColor, AshtonAttrLink ];
    }
    return self;
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

                if (alignment == kCTTextAlignmentLeft) attrDict[AshtonParagraphAttrTextAlignment] = @"left";
                if (alignment == kCTTextAlignmentRight) attrDict[AshtonParagraphAttrTextAlignment] = @"right";
                if (alignment == kCTTextAlignmentCenter) attrDict[AshtonParagraphAttrTextAlignment] = @"center";
                newAttrs[AshtonAttrParagraph] = attrDict;
            }
            if ([attrName isEqual:(id)kCTFontAttributeName]) {
                // produces: font
                CTFontRef font = (__bridge CTFontRef)attr;
                NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];

                CTFontSymbolicTraits symbolicTraits = CTFontGetSymbolicTraits(font);
                if ((symbolicTraits & kCTFontTraitBold) == kCTFontTraitBold) attrDict[AshtonFontAttrTraitBold] = @(YES);
                if ((symbolicTraits & kCTFontTraitItalic) == kCTFontTraitItalic) attrDict[AshtonFontAttrTraitItalic] = @(YES);

                NSArray *fontFeatures = CFBridgingRelease(CTFontCopyFeatureSettings(font));
                NSMutableSet *features = [NSMutableSet set];
                for (NSDictionary *feature in fontFeatures) {
                    [features addObject:@[feature[(id)kCTFontFeatureTypeIdentifierKey], feature[(id)kCTFontFeatureSelectorIdentifierKey]]];
                }

                attrDict[AshtonFontAttrFeatures] = features;
                attrDict[AshtonFontAttrPointSize] = @(CTFontGetSize(font));
                attrDict[AshtonFontAttrFamilyName] = CFBridgingRelease(CTFontCopyName(font, kCTFontFamilyNameKey));
                newAttrs[AshtonAttrFont] = attrDict;
            }
            if ([attrName isEqual:(id)kCTSuperscriptAttributeName]) {
                if ([attr intValue] == 1) newAttrs[AshtonAttrVerticalAlign] = AshtonVerticalAlignStyleSuper;
                if ([attr intValue] == -1) newAttrs[AshtonAttrVerticalAlign] = AshtonVerticalAlignStyleSub;
            }
            if ([attrName isEqual:(id)kCTUnderlineStyleAttributeName]) {
                // produces: underline
                if ([attr isEqual:@(kCTUnderlineStyleSingle)]) newAttrs[AshtonAttrUnderline] = AshtonUnderlineStyleSingle;
                if ([attr isEqual:@(kCTUnderlineStyleThick)]) newAttrs[AshtonAttrUnderline] = AshtonUnderlineStyleThick;
                if ([attr isEqual:@(kCTUnderlineStyleDouble)]) newAttrs[AshtonAttrUnderline] = AshtonUnderlineStyleDouble;
            }
            if ([attrName isEqual:(id)kCTUnderlineColorAttributeName]) {
                // produces: underlineColor
                newAttrs[AshtonAttrUnderlineColor] = [self arrayForColor:(__bridge CGColorRef)(attr)];
            }
            if ([attrName isEqual:(id)kCTForegroundColorAttributeName] || [attrName isEqual:(id)kCTStrokeColorAttributeName]) {
                // produces: color
                newAttrs[AshtonAttrColor] = [self arrayForColor:(__bridge CGColorRef)(attr)];
            }
            if ([self.attributesToPreserve containsObject:attrName]) {
                newAttrs[attrName] = attr;
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
                CTTextAlignment alignment = kCTTextAlignmentNatural;
                if ([attrDict[AshtonParagraphAttrTextAlignment] isEqualToString:@"left"]) alignment = kCTTextAlignmentLeft;
                if ([attrDict[AshtonParagraphAttrTextAlignment] isEqualToString:@"right"]) alignment = kCTTextAlignmentRight;
                if ([attrDict[AshtonParagraphAttrTextAlignment] isEqualToString:@"center"]) alignment = kCTTextAlignmentCenter;

                CTParagraphStyleSetting settings[] = {
                    { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &alignment },
                };

                newAttrs[(id)kCTParagraphStyleAttributeName] = CFBridgingRelease(CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(CTParagraphStyleSetting)));
            }
            if ([attrName isEqualToString:AshtonAttrFont]) {
                // consumes: font
                NSDictionary *attrDict = attr;
                newAttrs[(id)kCTFontAttributeName] = [AshtonUtils CTFontRefWithName:attrDict[AshtonFontAttrFamilyName]
                                                                               size:[attrDict[AshtonFontAttrPointSize] doubleValue]
                                                                          boldTrait:[attrDict[AshtonFontAttrTraitBold] isEqual:@(YES)]
                                                                        italicTrait:[attrDict[AshtonFontAttrTraitItalic] isEqual:@(YES)]
                                                                           features:attrDict[AshtonFontAttrFeatures]];
            }
            if ([attrName isEqualToString:AshtonAttrVerticalAlign]) {
                if ([attr isEqualToString:AshtonVerticalAlignStyleSuper]) newAttrs[(id)kCTSuperscriptAttributeName] = @(1);
                if ([attr isEqualToString:AshtonVerticalAlignStyleSub]) newAttrs[(id)kCTSuperscriptAttributeName] = @(-1);
            }
            if ([attrName isEqualToString:AshtonAttrUnderline]) {
                // consumes: underline
                if ([attr isEqualToString:@"single"]) newAttrs[(id)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleSingle);
                if ([attr isEqualToString:@"thick"]) newAttrs[(id)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleThick);
                if ([attr isEqualToString:@"double"]) newAttrs[(id)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleDouble);
            }
            if ([attrName isEqualToString:AshtonAttrUnderlineColor]) {
                // consumes: underlineColor
                newAttrs[(id)kCTUnderlineColorAttributeName] = [self colorForArray:attr];
            }
            if ([attrName isEqualToString:AshtonAttrColor]) {
                // consumes: color
                newAttrs[(id)kCTForegroundColorAttributeName] = [self colorForArray:attr];
            }
            if ([self.attributesToPreserve containsObject:attrName]) {
                newAttrs[attrName] = attr;
            }
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
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    id color = CFBridgingRelease(CGColorCreate(colorspace, components));
    CFRelease(colorspace);
    return color;
}

@end