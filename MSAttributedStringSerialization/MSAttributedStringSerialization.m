#import "MSAttributedStringSerialization.h"
#import "MSASSHTMLWriter.h"

@implementation MSAttributedStringSerialization

+ (NSString *)HTMLStringWithAttributedString:(NSAttributedString *)attributedString options:(MSHTMLWritingOptions)options {
    return [[[MSASSHTMLWriter alloc] initWithAttributedString:attributedString options:options] HTMLString];
}

+ (NSAttributedString *)attributedStringWithHTMLString:(NSString *)htmlString options:(MSHTMLReadingOptions)options {
    return nil;
}

@end
