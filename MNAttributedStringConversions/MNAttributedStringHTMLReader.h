@interface MNAttributedStringHTMLReader : NSObject < NSXMLParserDelegate >

+ (instancetype)sharedInstance;

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString;

@end
