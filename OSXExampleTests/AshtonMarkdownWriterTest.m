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

- (void)testParagraphs {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Test: bold That's italic. and both.\nnext paragraph"];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES } } range:NSMakeRange(6, 4)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(18, 6)];
    [string setAttributes:@{ AshtonAttrFont: @{ AshtonFontAttrTraitBold: @YES, AshtonFontAttrTraitItalic: @YES } } range:NSMakeRange(30, 4)];
    NSString *output = [writer markdownStringFromAttributedString:string];
    XCTAssertEqualObjects(output, @"Test: **bold** That's *italic*. and ***both***.\n\nnext paragraph\n\n", "bold, italic and bold italic writing failed.");
}

@end
