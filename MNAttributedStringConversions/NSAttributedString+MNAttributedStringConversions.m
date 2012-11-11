#import "NSAttributedString+MNAttributedStringConversions.h"
#import "MNAttributedStringCoreText.h"
#import "MNAttributedStringHTMLWriter.h"
#import "MNAttributedStringHTMLReader.h"
#if TARGET_OS_IPHONE
#import "MNAttributedStringUIKit.h"
#else
#import "MNAttributedStringAppKit.h"
#endif

@implementation NSAttributedString (MNAttributedStringConversions)

#if TARGET_OS_IPHONE
- (NSAttributedString *)intermediateAttributedStringWithUIKitAttributes {
    return [[MNAttributedStringUIKit shared] intermediateRepresentationWithTargetRepresentation:self];
}
+ (NSAttributedString *)attributedStringWithUIKitAttributes:(NSAttributedString *)inputWithIntermediateAttributes {
    return [[MNAttributedStringUIKit shared] targetRepresentationWithIntermediateRepresentation:inputWithIntermediateAttributes];
}
#else
- (NSAttributedString *)intermediateAttributedStringWithAppKitAttributes {
    return [[MNAttributedStringAppKit shared] intermediateRepresentationWithTargetRepresentation:self];
}
+ (NSAttributedString *)attributedStringWithAppKitAttributes:(NSAttributedString *)inputWithIntermediateAttributes {
    return [[MNAttributedStringAppKit shared] targetRepresentationWithIntermediateRepresentation:inputWithIntermediateAttributes];
}
#endif

- (NSAttributedString *)intermediateAttributedStringWithCoreTextAttributes {
    return [[MNAttributedStringCoreText shared] intermediateRepresentationWithTargetRepresentation:self];
}
+ (NSAttributedString *)attributedStringWithCoreTextAttributes:(NSAttributedString *)inputWithIntermediateAttributes {
    return [[MNAttributedStringCoreText shared] targetRepresentationWithIntermediateRepresentation:inputWithIntermediateAttributes];
}

- (NSString *)HTMLRepresentation {
    return [[MNAttributedStringHTMLWriter shared] HTMLStringFromAttributedString:self];
}

+ (NSAttributedString *)intermediateAttributedStringFromHTML:(NSString *)htmlString {
    return [[MNAttributedStringHTMLReader HTMLReader] attributedStringFromHTMLString:htmlString];
}

@end
