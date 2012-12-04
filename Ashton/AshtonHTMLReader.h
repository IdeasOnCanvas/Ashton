@interface AshtonHTMLReader : NSObject < NSXMLParserDelegate >

+ (instancetype)sharedInstance;

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString;

@end
