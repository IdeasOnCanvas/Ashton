#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, MSHTMLWritingOptions) {
    // The NSAttributedString contains CoreText attributes
    MSHTMLWritingCoreTextAttributes = (1UL << 0),

    // The NSAttributedString contains AppKit/UIKit attributes
    MSHTMLWritingCocoaAttributes = (1UL << 1)
};

typedef NS_OPTIONS(NSUInteger, MSHTMLReadingOptions) {
    // Create an NSAttributedString with CoreText attributes
    MSHTMLReadingCoreTextAttributes = (1UL << 0),

    // Create an NSAttributedString with AppKit/UIKit attributes
    MSHTMLReadingCocoaAttributes = (1UL << 1)
};

@interface MSAttributedStringSerialization : NSObject

+ (NSString *)HTMLStringWithAttributedString:(NSAttributedString *)attributedString options:(MSHTMLWritingOptions)options;
+ (NSAttributedString *)attributedStringWithHTMLString:(NSString *)htmlString options:(MSHTMLReadingOptions)options;

@end
