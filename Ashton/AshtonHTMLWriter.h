@interface AshtonHTMLWriter : NSObject

+ (instancetype)shared;

- (NSString *)HTMLStringFromAttributedString:(NSAttributedString *)input;

@end
