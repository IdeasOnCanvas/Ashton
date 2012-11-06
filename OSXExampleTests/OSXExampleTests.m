#import "OSXExampleTests.h"
#import "NSAttributedString+Ashton.h"

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
    NSAttributedString *sourceWithIntermediateAttrs = [[self readAttributedStringFromRTFFile:@"TextEdit Test Document"] intermediateAttributedStringWithAppKitAttributes];
    [self writeAttributedString:sourceWithIntermediateAttrs toFile:@"source"];

    NSAttributedString *transformed, *roundtripped;

    transformed = [NSAttributedString attributedStringWithAppKitAttributes:sourceWithIntermediateAttrs];
    roundtripped = [transformed intermediateAttributedStringWithAppKitAttributes];
    [self writeAttributedString:transformed toFile:@"transformed"];
    [self writeAttributedString:roundtripped toFile:@"roundtripped"];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [NSAttributedString attributedStringWithCoreTextAttributes:sourceWithIntermediateAttrs];
    roundtripped = [transformed intermediateAttributedStringWithCoreTextAttributes];
    [self writeAttributedString:transformed toFile:@"transformed"];
    [self writeAttributedString:roundtripped toFile:@"roundtripped"];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}

- (NSAttributedString *)readAttributedStringFromRTFFile:(NSString *)name {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"rtf"];
    NSTextView *text = [[NSTextView alloc] init];
    [text readRTFDFromFile:path];
    return [text attributedString];
}

- (void)writeAttributedString:(NSAttributedString *)input toFile:(NSString *)path {
#ifdef DEBUGDIR
    NSString *output = [NSString stringWithFormat:@"%@", input];
    path = [NSString stringWithFormat:@"%@%@", DEBUGDIR, path];
    [output writeToFile:path atomically:YES encoding:NSUnicodeStringEncoding error:nil];
#endif
}

- (void)writeAttributedString:(NSAttributedString *)input toRTFD:(NSString *)path {
    NSTextView *text = [[NSTextView alloc] init];
    [[text textStorage] setAttributedString:input];
    [text writeRTFDToFile:path atomically:YES];
}

@end
