@interface AshtonMarkdownReader : NSObject

+ (instancetype)sharedInstance;

- (NSAttributedString *)attributedStringFromMarkdownString:(NSString *)htmlString;

@end
