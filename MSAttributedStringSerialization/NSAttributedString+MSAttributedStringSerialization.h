@interface NSAttributedString (MSAttributedStringSerialization)

#if TARGET_OS_IPHONE
- (NSAttributedString *)intermediateAttributedStringWithUIKitAttributes;
+ (NSAttributedString *)attributedStringWithUIKitAttributes:(NSAttributedString *)inputWithIntermediateAttributes;
#else
- (NSAttributedString *)intermediateAttributedStringWithAppKitAttributes;
+ (NSAttributedString *)attributedStringWithAppKitAttributes:(NSAttributedString *)inputWithIntermediateAttributes;
#endif

- (NSAttributedString *)intermediateAttributedStringWithCoreTextAttributes;
+ (NSAttributedString *)attributedStringWithCoreTextAttributes:(NSAttributedString *)inputWithIntermediateAttributes;

@end
