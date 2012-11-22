#import "OSXExampleTests.h"
#import "NSAttributedString+MNAttributedStringConversions.h"
#import "MNAttributedStringAppKit.h"
#import "MNAttributedStringCoreText.h"
#import "MNAttributedStringHTMLWriter.h"
#import "MNAttributedStringHTMLReader.h"

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
    NSAttributedString *sourceWithIntermediateAttrs = [[MNAttributedStringAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:[self readAttributedStringFromRTFFile:@"TextEdit Test Document"]];

    NSAttributedString *transformed, *roundtripped;

    transformed = [[MNAttributedStringAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[MNAttributedStringAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [[MNAttributedStringCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[MNAttributedStringCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}

- (void)testTest1 {
    NSAttributedString *sourceWithIntermediateAttrs = [[MNAttributedStringAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:[self readAttributedStringFromRTFFile:@"Test1"]];

    NSAttributedString *transformed, *roundtripped;

    transformed = [[MNAttributedStringAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[MNAttributedStringAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [[MNAttributedStringCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[MNAttributedStringCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}

- (void)testTypography {
    NSAttributedString *sourceWithIntermediateAttrs = [[MNAttributedStringAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:[self readAttributedStringFromRTFFile:@"Typography"]];

    NSAttributedString *transformed, *roundtripped;

    transformed = [[MNAttributedStringAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[MNAttributedStringAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [[MNAttributedStringCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[MNAttributedStringCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}

- (void)testIsolated {
    NSAttributedString *sourceWithIntermediateAttrs = [[MNAttributedStringAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:[self readAttributedStringFromRTFFile:@"isolated"]];

    NSAttributedString *transformed, *roundtripped;

    transformed = [[MNAttributedStringAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[MNAttributedStringAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from AppKit representation");

    transformed = [[MNAttributedStringCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:sourceWithIntermediateAttrs];
    roundtripped = [[MNAttributedStringCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:transformed];
    STAssertEqualObjects(sourceWithIntermediateAttrs, roundtripped, @"Converting to/from CoreText representation");
}

- (void)testHTML {
    NSAttributedString *source = [[MNAttributedStringAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:[self readAttributedStringFromRTFFile:@"Test1"]];

    NSString *htmlString = [[MNAttributedStringHTMLWriter sharedInstance] HTMLStringFromAttributedString:source];
    NSAttributedString *intermediate = [[MNAttributedStringHTMLReader sharedInstance] attributedStringFromHTMLString:htmlString];
    htmlString = [[MNAttributedStringHTMLWriter sharedInstance] HTMLStringFromAttributedString:intermediate];
    NSAttributedString *back = [[MNAttributedStringHTMLReader sharedInstance] attributedStringFromHTMLString:htmlString];

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
