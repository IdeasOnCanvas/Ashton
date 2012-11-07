@interface AshtonHTMLReader : NSObject < NSXMLParserDelegate >

+ (instancetype)shared;

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString;

@end
