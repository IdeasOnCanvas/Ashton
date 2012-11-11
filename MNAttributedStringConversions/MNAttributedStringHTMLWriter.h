@interface MNAttributedStringHTMLWriter : NSObject

+ (instancetype)shared;

- (NSString *)HTMLStringFromAttributedString:(NSAttributedString *)input;

@end
