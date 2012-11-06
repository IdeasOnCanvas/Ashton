#import "NSAttributedString+Ashton.h"
#import "AshtonCoreText.h"
#import "AshtonHTMLWriter.h"
#if TARGET_OS_IPHONE
#import "AshtonUIKit.h"
#else
#import "AshtonAppKit.h"
#endif

@implementation NSAttributedString (Ashton)

#if TARGET_OS_IPHONE
- (NSAttributedString *)intermediateAttributedStringWithUIKitAttributes {
    return [[AshtonUIKit shared] intermediateRepresentationWithTargetRepresentation:self];
}
+ (NSAttributedString *)attributedStringWithUIKitAttributes:(NSAttributedString *)inputWithIntermediateAttributes {
    return [[AshtonUIKit shared] targetRepresentationWithIntermediateRepresentation:inputWithIntermediateAttributes];
}
#else
- (NSAttributedString *)intermediateAttributedStringWithAppKitAttributes {
    return [[AshtonAppKit shared] intermediateRepresentationWithTargetRepresentation:self];
}
+ (NSAttributedString *)attributedStringWithAppKitAttributes:(NSAttributedString *)inputWithIntermediateAttributes {
    return [[AshtonAppKit shared] targetRepresentationWithIntermediateRepresentation:inputWithIntermediateAttributes];
}
#endif

- (NSAttributedString *)intermediateAttributedStringWithCoreTextAttributes {
    return [[AshtonCoreText shared] intermediateRepresentationWithTargetRepresentation:self];
}
+ (NSAttributedString *)attributedStringWithCoreTextAttributes:(NSAttributedString *)inputWithIntermediateAttributes {
    return [[AshtonCoreText shared] targetRepresentationWithIntermediateRepresentation:inputWithIntermediateAttributes];
}

- (NSString *)HTMLRepresentation {
    return [[AshtonHTMLWriter shared] HTMLStringFromAttributedString:self];
}

@end
