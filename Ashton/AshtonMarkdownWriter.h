@interface AshtonMarkdownWriter : NSObject

+ (instancetype)sharedInstance;

- (NSString *)markdownStringFromAttributedString:(NSAttributedString *)input;

@end
