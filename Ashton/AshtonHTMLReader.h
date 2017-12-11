@interface AshtonHTMLReader : NSObject < NSXMLParserDelegate >

+ (instancetype)HTMLReader;
+ (void)clearStylesCache;
- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString;
- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString error:(__autoreleasing NSError **)error;

@end
