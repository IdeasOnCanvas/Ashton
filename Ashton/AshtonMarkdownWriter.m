#import "AshtonMarkdownWriter.h"

@implementation AshtonMarkdownWriter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AshtonMarkdownWriter *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AshtonMarkdownWriter alloc] init];
    });
    return sharedInstance;
}

- (NSString *)markdownStringFromAttributedString:(NSAttributedString *)input {
    return nil;
}

@end
