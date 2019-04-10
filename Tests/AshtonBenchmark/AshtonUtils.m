#import "AshtonUtils.h"
#import <CoreText/CoreText.h>

@implementation AshtonUtils

+ (id)CTFontRefWithFamilyName:(NSString *)familyName postScriptName:(NSString *)postScriptName size:(CGFloat)pointSize boldTrait:(BOOL)isBold italicTrait:(BOOL)isItalic features:(NSArray *)features {

    NSMutableDictionary *cache = [self fontsCache];
    NSMutableDictionary *descriptorAttributes = [NSMutableDictionary dictionaryWithCapacity:3];
    descriptorAttributes[(id)kCTFontSizeAttribute] = @(pointSize);
    if (familyName) descriptorAttributes[(id)kCTFontNameAttribute] = familyName;
    if (postScriptName) descriptorAttributes[(id)kCTFontNameAttribute] = postScriptName;

    if (features) {
        NSMutableArray *fontFeatures = [NSMutableArray array];
        for (NSArray *feature in features) {
            [fontFeatures addObject:@{(id)kCTFontFeatureTypeIdentifierKey:feature[0], (id)kCTFontFeatureSelectorIdentifierKey:feature[1]}];
        }
        descriptorAttributes[(id)kCTFontFeatureSettingsAttribute] = fontFeatures;
    }
    id font;
    id cached_font = cache[descriptorAttributes];

    if (cached_font) {
        font = cached_font;
    } else {
        CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)(descriptorAttributes));

        font = CFBridgingRelease(CTFontCreateWithFontDescriptor(descriptor, pointSize, NULL));
        CFRelease(descriptor);

        cache[descriptorAttributes] = font;
    }

    // We ignore symbolic traits when a postScriptName is given, because the postScriptName already encodes bold/italic and if we
    // specify it again as a trait we get different fonts (e.g. Helvetica-Oblique becomes Helvetica-LightOblique)
    CTFontSymbolicTraits symbolicTraits = 0; // using CTFontGetSymbolicTraits also makes CTFontCreateCopyWithSymbolicTraits fail
    if (!postScriptName && isBold) symbolicTraits = symbolicTraits | kCTFontTraitBold;
    if (!postScriptName && isItalic) symbolicTraits = symbolicTraits | kCTFontTraitItalic;
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
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
    NSFontDescriptor *fontDescriptor = [font fontDescriptor];
    font = [NSFont fontWithDescriptor:fontDescriptor size:fontDescriptor.pointSize];
#endif
    return font;
}

+ (NSMutableDictionary *)fontsCache
{
    static NSMutableDictionary *cache = nil;
    if (!cache) {
        cache = [NSMutableDictionary dictionary];
    }
    return cache;
}

+ (void)clearFontsCache
{
    [[self fontsCache] removeAllObjects];
}

+ (NSArray *)arrayForCGColor:(CGColorRef)color {
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

@end
