#import "AshtonUtils.h"
#import <CoreText/CoreText.h>

@implementation AshtonUtils

+ (id)CTFontRefWithName:(NSString *)familyName size:(CGFloat)pointSize boldTrait:(BOOL)isBold italicTrait:(BOOL)isItalic features:(NSArray *)features {
    NSDictionary *descriptorAttributes = @{ (id)kCTFontNameAttribute:familyName };
    CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)(descriptorAttributes));

    if (features) {
        NSMutableArray *fontFeatures = [NSMutableArray array];
        for (NSArray *feature in features) {
            [fontFeatures addObject:@{(id)kCTFontFeatureTypeIdentifierKey:feature[0], (id)kCTFontFeatureSelectorIdentifierKey:feature[1]}];
        }
        descriptorAttributes = @{(id)kCTFontFeatureSettingsAttribute:fontFeatures};
        CTFontDescriptorRef newDescriptor = CTFontDescriptorCreateCopyWithAttributes(descriptor, (__bridge CFDictionaryRef)(descriptorAttributes));
        CFRelease(descriptor);
        descriptor = newDescriptor;
    }

    CTFontRef font = CTFontCreateWithFontDescriptor(descriptor, pointSize, NULL);
    CFRelease(descriptor);

    CTFontSymbolicTraits symbolicTraits = 0; // using CTFontGetSymbolicTraits also makes CTFontCreateCopyWithSymbolicTraits fail
    if (isBold) symbolicTraits = symbolicTraits | kCTFontTraitBold;
    if (isItalic) symbolicTraits = symbolicTraits | kCTFontTraitItalic;
    if (symbolicTraits != 0) {
        // Unfortunately CTFontCreateCopyWithSymbolicTraits returns NULL when there are no symbolicTraits (== 0)
        // Is there a better way to detect "no" symbolic traits?
        CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits(font, 0.0, NULL, symbolicTraits, symbolicTraits);
        // And even worse, if a font is defined to be "only" bold (like Arial Rounded MT Bold is) then
        // CTFontCreateCopyWithSymbolicTraits also returns NULL
        if (newFont != NULL) {
            CFRelease(font);
            font = newFont;
        }
    }
    return CFBridgingRelease(font);
}

@end
