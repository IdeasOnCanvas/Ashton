#import <Foundation/Foundation.h>

@interface MSAttributedStringSerialization : NSObject

+ (NSString *)HTMLStringWithAttributedString:(NSAttributedString *)attributedString;
+ (NSAttributedString *)attributedStringWithHTMLString:(NSString *)htmlString;

@end
