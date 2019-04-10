#import "AshtonMarkdownReader.h"

@implementation AshtonMarkdownReader

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AshtonMarkdownReader *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AshtonMarkdownReader alloc] init];
    });
    return sharedInstance;
}

- (NSAttributedString *)attributedStringFromMarkdownString:(NSString *)htmlString {
    return nil;
}

@end
