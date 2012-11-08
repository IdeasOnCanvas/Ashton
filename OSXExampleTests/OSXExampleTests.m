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

    NSAttributedString *transformed, *roundtripped;

    transformed = [NSAttributedString attributedStringWithAppKitAttributes:sourceWithIntermediateAttrs];
    roundtripped = [transformed intermediateAttributedStringWithAppKitAttributes];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [NSAttributedString attributedStringWithCoreTextAttributes:sourceWithIntermediateAttrs];
    roundtripped = [transformed intermediateAttributedStringWithCoreTextAttributes];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}

- (void)testTest1 {
    // read a source RTF and transform it once so we remove all non-supported styles. Then transform it again and compare.
    NSAttributedString *sourceWithIntermediateAttrs = [[self readAttributedStringFromRTFFile:@"Test1"] intermediateAttributedStringWithAppKitAttributes];

    NSAttributedString *transformed, *roundtripped;

    transformed = [NSAttributedString attributedStringWithAppKitAttributes:sourceWithIntermediateAttrs];
    roundtripped = [transformed intermediateAttributedStringWithAppKitAttributes];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [NSAttributedString attributedStringWithCoreTextAttributes:sourceWithIntermediateAttrs];
    roundtripped = [transformed intermediateAttributedStringWithCoreTextAttributes];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}


- (void)testHTML {
    NSAttributedString *source = [[self readAttributedStringFromRTFFile:@"Test1"] intermediateAttributedStringWithAppKitAttributes];

    NSString *htmlString = [source HTMLRepresentation];
    NSAttributedString *intermediate = [NSAttributedString intermediateAttributedStringFromHTML:htmlString];
    htmlString = [intermediate HTMLRepresentation];
    NSAttributedString *back = [NSAttributedString intermediateAttributedStringFromHTML:htmlString];
    STAssertEqualObjects(back, intermediate, @"Converting to/from HTML");
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
