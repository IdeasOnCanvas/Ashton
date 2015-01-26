@interface AshtonHTMLReader : NSObject < NSXMLParserDelegate >

+ (instancetype)HTMLReader;
+ (void)clearStylesCache;
- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString;

@end
