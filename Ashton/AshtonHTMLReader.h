@interface AshtonHTMLReader : NSObject

+ (instancetype)shared;

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString;

@end
