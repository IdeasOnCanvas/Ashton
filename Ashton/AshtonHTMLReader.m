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
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[htmlString dataUsingEncoding:NSUTF8StringEncoding]];
    parser.delegate = self;
    [parser parse];
    return nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSLog(@"%@", string);
}

@end
