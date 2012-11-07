#import "AshtonHTMLReader.h"

@implementation AshtonHTMLReader

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static AshtonHTMLReader *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AshtonHTMLReader alloc] init];
    });
    return sharedInstance;
}

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString {
    return nil;
}

@end
