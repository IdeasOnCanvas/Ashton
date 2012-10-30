#import "OSXExampleTests.h"
#import "MSAttributedStringSerialization.h"

@implementation OSXExampleTests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown {
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testTextEditTestDocument {
    NSAttributedString *source = [self readAttributedStringFromRTFFile:@"TextEdit Test Document"];

    [MSAttributedStringSerialization HTMLStringWithAttributedString:source options:MSHTMLWritingCocoaAttributes];

    STAssertNotNil(source, @"Couldn't read document");
}

- (NSAttributedString *)readAttributedStringFromRTFFile:(NSString *)name {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"rtf"];
    NSTextView *text = [[NSTextView alloc] init];
    [text readRTFDFromFile:path];
    return [text attributedString];
}

@end
