@interface NSAttributedString (MSAttributedStringSerialization)

#if TARGET_OS_IPHONE
- (NSAttributedString *)intermediateAttributedStringWithUIKitAttributes;
#else
- (NSAttributedString *)intermediateAttributedStringWithAppKitAttributes;
+ (NSAttributedString *)attributedStringWithAppKitAttributes:(NSAttributedString *)inputWithIntermediateAttributes;
#endif

- (NSAttributedString *)intermediateAttributedStringWithCoreTextAttributes;
+ (NSAttributedString *)attributedStringWithUIAttributes:(NSAttributedString *)inputWithIntermediateAttributes;

@end
