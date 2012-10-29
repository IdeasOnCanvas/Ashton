@interface MSASSHTMLWriter : NSObject

- (id)initWithAttributedString:(NSAttributedString *)attributedString;

@property (nonatomic, readonly) NSString *HTMLString;

@end
