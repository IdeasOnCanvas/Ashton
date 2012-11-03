@interface NSAttributedString (MSAttributedStringSerialization)

#if TARGET_OS_IPHONE
- (NSAttributedString *)intermediateAttributedStringWithUIKitAttributes;
#else
- (NSAttributedString *)intermediateAttributedStringWithAppKitAttributes;
#endif

- (NSAttributedString *)intermediateAttributedStringWithCoreTextAttributes;

@end
