#import <XCTest/XCTest.h>
#import "AshtonMarkdownWriter.h"
#import "AshtonIntermediate.h"

@interface AshtonMarkdownWriterTest : XCTestCase

@end

@implementation AshtonMarkdownWriterTest {
    AshtonMarkdownWriter *writer;
}

- (void)setUp {
    writer = [[AshtonMarkdownWriter alloc] init];
    [super setUp];
}

- (void)testBoldItalic {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: bold That's italic. and both."];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES } } range:NSMakeRange(6, 4)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(18, 6)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES, AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(30, 4)];
    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"Test: **bold** That's *italic*. and ***both***.\n\n", "bold, italic and bold italic writing failed.");
}

- (void)testItalicWithSmartSuffixes {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: That's italic. and not."];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(13, 8)];
    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"Test: That's *italic*. and not.\n\n", "bold, italic and bold italic writing failed.");
}

- (void)testBoldItalicAcrossWords {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: bold and bold and bold That's italic. and both."];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES } } range:NSMakeRange(6, 22)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(36, 6)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES, AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(48, 4)];
    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"Test: **bold and bold and bold** That's *italic*. and ***both***.\n\n", "bold, italic and bold italic writing failed.");
}

- (void)testBoldItalicAcrossWordsNested {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: bold and italic and bold That's italic. and both."];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES } } range:NSMakeRange(6, 24)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES, AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(15, 6)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(38, 6)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES, AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(50, 4)];
    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"Test: **bold and *italic* and bold** That's *italic*. and ***both***.\n\n", "bold, italic and bold italic writing failed.");
}

- (void)testStrikethrough {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: strikethrough. and strikethrough with bold."];
    [string setAttributes:@{ AshtonAttrStrikethrough: AshtonStrikethroughStyleSingle } range:NSMakeRange(6, 13)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES }, AshtonAttrStrikethrough: AshtonStrikethroughStyleSingle } range:NSMakeRange(25, 23)];;
    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"Test: ~~strikethrough~~. and ~~**strikethrough with bold**~~.\n\n");
}

- (void)testLinks {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: link. and link with bold ok last work also link."];
    [string setAttributes:@{ AshtonAttrLink: @"http://apple.com" } range:NSMakeRange(6, 4)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES }, AshtonAttrLink: @"http://google.com" } range:NSMakeRange(16, 14)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES, AshtonFontAttrTraitItalic: @YES }, AshtonAttrLink: @"http://amazon.com", AshtonAttrStrikethrough: AshtonStrikethroughStyleSingle } range:NSMakeRange(34, 19)];
    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"Test: [link](http://apple.com). and [**link with bold**](http://google.com) ok [~~***last work also link***~~.](http://amazon.com)\n\n");
}

- (void)testAllLink {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: link. and link with bold ok last work also link."];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES } } range:NSMakeRange(16, 14)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES, AshtonFontAttrTraitItalic: @YES }, AshtonAttrStrikethrough: AshtonStrikethroughStyleSingle } range:NSMakeRange(34, 19)];
    [string addAttribute:AshtonAttrLink value:@"http://apple.com" range:NSMakeRange(0, string.length)];
    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"[Test: link. and **link with bold** ok ~~***last work also link***~~.](http://apple.com)\n\n");
}

- (void)testLinksWithChangingAttrsInside {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: bold with link italic inside all strikethrough."];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES } } range:NSMakeRange(6, 9)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES }, AshtonAttrLink: @"http://apple.com" } range:NSMakeRange(16, 5)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitItalic: @YES }, AshtonAttrLink: @"http://apple.com" } range:NSMakeRange(21, 5)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES }, AshtonAttrLink: @"http://apple.com" } range:NSMakeRange(26, 8)];
    [string setAttributes:@{ AshtonAttrStrikethrough: AshtonStrikethroughStyleDouble } range:NSMakeRange(35, 18)];

    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"Test: **bold with** [**link** *italic* **inside**](http://apple.com) ~~all strikethrough~~.\n\n");
}

- (void)testLinksWithNestedAttrsInside {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: bold with link italic inside all strikethrough."];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES } } range:NSMakeRange(6, 9)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES }, AshtonAttrLink: @"http://apple.com" } range:NSMakeRange(16, 5)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitItalic: @YES, AshtonFontAttrTraitBold: @YES }, AshtonAttrLink: @"http://apple.com" } range:NSMakeRange(21, 5)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES }, AshtonAttrLink: @"http://apple.com" } range:NSMakeRange(26, 8)];
    [string setAttributes:@{ AshtonAttrStrikethrough: AshtonStrikethroughStyleDouble } range:NSMakeRange(35, 18)];

    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"Test: **bold with** [**link *italic* inside**](http://apple.com) ~~all strikethrough~~.\n\n");
}

- (void)testParagraphs {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: bold That's italic. and both.\nnext paragraph"];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES } } range:NSMakeRange(6, 4)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(18, 6)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES, AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(30, 4)];
    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"Test: **bold** That's *italic*. and ***both***.\n\nnext paragraph\n\n", "bold, italic and bold italic writing failed.");
}

@end
