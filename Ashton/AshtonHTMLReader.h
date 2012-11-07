@interface AshtonHTMLReader : NSObject < NSXMLParserDelegate >

+ (instancetype)HTMLReader;

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString;

@end
