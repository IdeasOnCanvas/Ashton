#import "MSASSHTMLWriterAppKit.h"

@implementation MSASSHTMLWriterAppKit

- (NSString *)tagNameForAttribute:(id)attr withName:(NSString *)attrName {
    NSLog(@"%@", attrName);
    return @"span";
}
- (NSDictionary *)stylesForAttribute:(id)attr withName:(NSString *)attrName {
    return [NSDictionary dictionary];
}

@end
