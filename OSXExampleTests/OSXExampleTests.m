#import "OSXExampleTests.h"
#import "NSAttributedString+MSAttributedStringSerialization.h"

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
    // read a source RTF and transform it once so we remove all non-supported styles. Then transform it again and compare.
    NSAttributedString *source = [NSAttributedString attributedStringWithAppKitAttributes:[[self readAttributedStringFromRTFFile:@"TextEdit Test Document"] intermediateAttributedStringWithAppKitAttributes]];
    NSAttributedString *output = [NSAttributedString attributedStringWithAppKitAttributes:[source intermediateAttributedStringWithAppKitAttributes]];

    STAssertEqualObjects(source, output, @"Converting to/from intermediate representation failed");
}

- (NSAttributedString *)readAttributedStringFromRTFFile:(NSString *)name {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"rtf"];
    NSTextView *text = [[NSTextView alloc] init];
    [text readRTFDFromFile:path];
    return [text attributedString];
}

@end
