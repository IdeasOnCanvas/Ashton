#import "AshtonHTMLWriterTests.h"
#import "AshtonHTMLWriter.h"

@interface AshtonHTMLWriter (Private)
- (NSArray *)sortedStyleKeyArray:(NSArray *)keys;
@end

@implementation AshtonHTMLWriterTests {
    AshtonHTMLWriter *writer;
}

- (void)setUp {
    [super setUp];
    writer = [[AshtonHTMLWriter alloc] init];
}

- (void)tearDown {
    writer = nil;
    [super tearDown];
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
