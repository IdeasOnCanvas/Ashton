@interface AshtonHTMLReader : NSObject < NSXMLParserDelegate >

+ (instancetype)HTMLReader;
+ (void)emptyStylesCache;
- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString;

@end
