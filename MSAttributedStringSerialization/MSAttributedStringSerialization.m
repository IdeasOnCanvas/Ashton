#import "MSAttributedStringSerialization.h"
#import "MSASSHTMLWriter.h"
#import "MSASSHTMLWriterCoreText.h"

#if TARGET_OS_IPHONE
#import "MSASSHTMLWriterUIKit.h"
#else
#import "MSASSHTMLWriterAppKit.h"
#endif

@implementation MSAttributedStringSerialization

+ (NSString *)HTMLStringWithAttributedString:(NSAttributedString *)attributedString options:(MSHTMLWritingOptions)options {
    MSASSHTMLWriter *writer = nil;
    if ((options & MSHTMLWritingCoreTextAttributes) == MSHTMLWritingCoreTextAttributes) {
        writer = [MSASSHTMLWriterCoreText alloc];
    } else if ((options & MSHTMLWritingCocoaAttributes) == MSHTMLWritingCocoaAttributes) {
#if TARGET_OS_IPHONE
        writer = [MSASSHTMLWriterUIKit alloc];
#else
        writer = [MSASSHTMLWriterAppKit alloc];
#endif
    }

    return [[writer initWithAttributedString:attributedString options:options] createHTMLString];
}

+ (NSAttributedString *)attributedStringWithHTMLString:(NSString *)htmlString options:(MSHTMLReadingOptions)options {
    return nil;
}

@end
