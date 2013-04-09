#import "OSXExampleTests.h"
#import "NSAttributedString+Ashton.h"
#import "AshtonAppKit.h"
#import "AshtonCoreText.h"
#import "AshtonHTMLWriter.h"
#import "AshtonHTMLReader.h"

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
    NSAttributedString *sourceWithIntermediateAttrs = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:[self readAttributedStringFromRTFFile:@"TextEdit Test Document"]];

    NSAttributedString *transformed, *roundtripped;

    transformed = [[AshtonAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [[AshtonCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[AshtonCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}

- (void)testTest1 {
    NSAttributedString *sourceWithIntermediateAttrs = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:[self readAttributedStringFromRTFFile:@"Test1"]];

    NSAttributedString *transformed, *roundtripped;

    transformed = [[AshtonAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [[AshtonCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[AshtonCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}

- (void)testTypography {
    NSAttributedString *sourceWithIntermediateAttrs = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:[self readAttributedStringFromRTFFile:@"Typography"]];

    NSAttributedString *transformed, *roundtripped;

    transformed = [[AshtonAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [[AshtonCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[AshtonCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}

- (void)testIsolated {
    NSAttributedString *sourceWithIntermediateAttrs = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:[self readAttributedStringFromRTFFile:@"isolated"]];

    NSAttributedString *transformed, *roundtripped;

    transformed = [[AshtonAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [[AshtonCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[AshtonCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}

- (void)testHTML {
    NSAttributedString *source = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:[self readAttributedStringFromRTFFile:@"Test1"]];

    NSString *htmlString = [[AshtonHTMLWriter sharedInstance] HTMLStringFromAttributedString:source];
    NSAttributedString *intermediate = [[AshtonHTMLReader HTMLReader] attributedStringFromHTMLString:htmlString];
    htmlString = [[AshtonHTMLWriter sharedInstance] HTMLStringFromAttributedString:intermediate];
    NSAttributedString *back = [[AshtonHTMLReader HTMLReader] attributedStringFromHTMLString:htmlString];

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
