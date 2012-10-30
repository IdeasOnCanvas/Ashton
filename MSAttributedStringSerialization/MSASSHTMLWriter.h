#import "MSAttributedStringSerialization.h"

@interface MSASSHTMLWriter : NSObject

- (id)initWithAttributedString:(NSAttributedString *)attributedString options:(MSHTMLWritingOptions)options;

- (NSString *)createHTMLString;

@property (nonatomic, readonly, assign) MSHTMLWritingOptions options;
@property (nonatomic, readonly, strong) NSAttributedString *input;

// Overwrite in subclasses
- (NSString *)tagNameForAttribute:(id)attr withName:(NSString *)attrName;
- (NSDictionary *)stylesForAttribute:(id)attr withName:(NSString *)attrName;

@end
