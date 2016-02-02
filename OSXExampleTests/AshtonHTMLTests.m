#import "AshtonHTMLTests.h"
#import "AshtonHTMLReader.h"
#import "AshtonHTMLWriter.h"
#import "AshtonIntermediate.h"

@implementation AshtonHTMLTests {
    AshtonHTMLReader *reader;
    AshtonHTMLWriter *writer;
}

- (void)setUp {
    [super setUp];
    reader = [[AshtonHTMLReader alloc] init];
    writer = [[AshtonHTMLWriter alloc] init];
}

- (void)tearDown {
    reader = nil;
    writer = nil;
    [super tearDown];
}

- (void)testHTMLEscapingInAhrefInline {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: Link to test. That's it"];
    [string setAttributes:@{ AshtonAttrLink: @"http://google.com/?a='b\"&c=<>" } range:NSMakeRange(6, 13)];
    NSString *htmlString = [writer HTMLStringFromAttributedString:string];
    NSAttributedString *roundtripped = [reader attributedStringFromHTMLString:htmlString];
    XCTAssertEqualObjects(string, roundtripped, @"HTML escaping of inline link failed");
}

- (void)testHTMLEscapingInAhrefParagraph {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: Link to test. That's it" attributes:@{ AshtonAttrLink: @"http://google.com/?a='b\"&c=<>" }];
    NSString *htmlString = [writer HTMLStringFromAttributedString:string];
    NSAttributedString *roundtripped = [reader attributedStringFromHTMLString:htmlString];
    XCTAssertEqualObjects(string, roundtripped, @"HTML escaping of linked paragraph failed");
}

- (void)testBackgroundColor {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: Background Color."];
    [string setAttributes:@{ AshtonAttrBackgroundColor: @[ @(1), @(1), @(0), @(1.) ] } range:NSMakeRange(6, 10)];
    NSString *htmlString = [writer HTMLStringFromAttributedString:string];
    NSAttributedString *roundtripped = [reader attributedStringFromHTMLString:htmlString];
    XCTAssertEqualObjects(string, roundtripped, @"HTML output for background color failed");
}

- (void)testCombiningOfParagraphsAttributes {
    NSString *ashtonRep = @"<p style='color: rgba(52, 72, 83, 1.000000); font: 18px \"Palatino\"; -cocoa-font-postscriptname: \"Palatino-Roman\"; '>Line1</p><p style='color: rgba(52, 72, 83, 1.000000); font: 18px \"Palatino\"; -cocoa-font-postscriptname: \"Palatino-Roman\"; '>Line2</p>";
    NSAttributedString *attrString = [[AshtonHTMLReader HTMLReader] attributedStringFromHTMLString:ashtonRep];
    NSRange range = NSMakeRange(0, attrString.length);
    NSRange maxRange;
    [attrString attributesAtIndex:0 longestEffectiveRange:&maxRange inRange:range];
    XCTAssert(NSEqualRanges(maxRange, range), @"%@ != %@", NSStringFromRange(maxRange), NSStringFromRange(range));
}

- (void)testReadStringWithMissingFontFamilyName {
    NSString *ashtonRep = @"<p style='text-align: left; '><span style='color: rgba(52, 72, 83, 1.000000); font: 18px \"\"; -cocoa-font-postscriptname: \"FontAwesome\"; '>\\UF016</span><span style='color: rgba(52, 72, 83, 1.000000); font: 18px \"Helvetica Neue\"; -cocoa-font-postscriptname: \"HelveticaNeue\"; '>  1. Numbers</span></p>";
    NSAttributedString *attrString = [[AshtonHTMLReader HTMLReader] attributedStringFromHTMLString:ashtonRep];
    NSDictionary *attributes = [attrString attributesAtIndex:0 effectiveRange:NULL];
    XCTAssert([attributes[@"font"][@"postScriptName"] isEqualToString:@"FontAwesome"]);
}

@end
