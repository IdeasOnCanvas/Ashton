#import "AshtonCSSTests.h"
#import "AshtonHTMLReader.h"
#import "AshtonHTMLWriter.h"

@interface AshtonHTMLReader (Private)
- (NSDictionary *)attributesForStyleString:(NSString *)styleString href:(NSString *)href;
@end

@interface AshtonHTMLWriter (Private)
- (NSArray *)sortedStyleKeyArray:(NSArray *)keys;
- (NSString *)styleStringForAttributes:(NSDictionary *)attrs skipParagraphStyles:(BOOL)skipParagraphStyles;
@end

@implementation AshtonCSSTests {
    AshtonHTMLWriter *writer;
    AshtonHTMLReader *reader;
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

- (void)assertStyleStringRoundtrip:(NSString *)styleString {
    [self assertStyleStringsEqual:styleString expected:styleString];
}

- (void)assertStyleStringsEqual:(NSString *)styleString expected:(NSString *)expectedStyleString {
    expectedStyleString = [NSString stringWithFormat:@" style='%@'", expectedStyleString];
    NSDictionary *attrs = [reader attributesForStyleString:styleString href:nil];
    styleString = [writer styleStringForAttributes:attrs skipParagraphStyles:NO];
    STAssertEqualObjects(styleString, expectedStyleString, @"style strings not equal");
}

- (void)testMisorderedFontFeaturesAttribute {
    NSString *styleString = @"-cocoa-font-features: 3/3; font: 14px \"Hoefler Text\"; text-align: left; color: rgba(0, 0, 0, 1.000000); ";
    NSString *expectedStyleString = @"color: rgba(0, 0, 0, 1.000000); font: 14px \"Hoefler Text\"; text-align: left; -cocoa-font-features: 3/3; ";
    [self assertStyleStringsEqual:styleString expected:expectedStyleString];
}

- (void)testSimpleFontAttributes {
    [self assertStyleStringRoundtrip:@"font: 14px \"Helvetica\"; "];
    [self assertStyleStringRoundtrip:@"font: bold 14px \"Helvetica\"; "];
    [self assertStyleStringRoundtrip:@"font: bold italic 14px \"Helvetica\"; "];
}

- (void)testFutureFontAttribute {
    NSString *styleString, *expectedStyleString;

    styleString = @"font: bold italic 14px \"Helvetica\", \"Arial\", sans-serif; ";
    expectedStyleString = @"font: bold italic 14px \"Helvetica\"; ";
    [self assertStyleStringsEqual:styleString expected:expectedStyleString];

    styleString = @"color: rgba(0, 0, 0, 0.000000); font: 14px \"Helvetica\", \"Arial\", sans-serif; text-align: left; ";
    expectedStyleString = @"color: rgba(0, 0, 0, 0.000000); font: 14px \"Helvetica\"; text-align: left; ";
    [self assertStyleStringsEqual:styleString expected:expectedStyleString];
}

- (void)testCustomStyleSort1 {
    NSArray *keys         = @[ @"-a", @"-b", @"a", @"b", @"c" ];
    NSArray *expectedKeys = @[ @"a", @"b", @"c", @"-a", @"-b" ];

    NSArray *sortedKeys = [writer sortedStyleKeyArray:keys];
    STAssertEqualObjects(sortedKeys, expectedKeys, @"Sort keys starting with - to the end");
}

- (void)testCustomStyleSort2 {
    NSArray *keys         = @[ @"-cocoa-font-features", @"font", @"text-align" ];
    NSArray *expectedKeys = @[ @"font", @"text-align", @"-cocoa-font-features" ];

    NSArray *sortedKeys = [writer sortedStyleKeyArray:keys];
    STAssertEqualObjects(sortedKeys, expectedKeys, @"Sort keys starting with - to the end");
}

@end
