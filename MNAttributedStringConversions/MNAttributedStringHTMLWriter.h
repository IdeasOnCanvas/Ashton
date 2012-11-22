@interface MNAttributedStringHTMLWriter : NSObject

+ (instancetype)sharedInstance;

- (NSString *)HTMLStringFromAttributedString:(NSAttributedString *)input;

@end
