#import "MSAttributedStringSerialization.h"

@interface MSASSHTMLWriter : NSObject

- (id)initWithAttributedString:(NSAttributedString *)attributedString options:(MSHTMLWritingOptions)options;

@property (nonatomic, readonly) MSHTMLWritingOptions options;
@property (nonatomic, readonly) NSString *HTMLString;

@end
