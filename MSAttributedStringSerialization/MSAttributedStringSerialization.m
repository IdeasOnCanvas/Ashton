#import "MSAttributedStringSerialization.h"
#import "MSASSHTMLWriter.h"

@implementation MSAttributedStringSerialization

+ (NSString *)HTMLStringWithAttributedString:(NSAttributedString *)attributedString {
    return [[[MSASSHTMLWriter alloc] initWithAttributedString:attributedString] HTMLString];
}

+ (NSAttributedString *)attributedStringWithHTMLString:(NSString *)htmlString {
    return nil;
}

@end
