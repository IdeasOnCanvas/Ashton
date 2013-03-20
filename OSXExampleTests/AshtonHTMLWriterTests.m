#import "AshtonHTMLWriterTests.h"
#import "AshtonHTMLWriter.h"

@implementation AshtonHTMLWriterTests
- (void)setUp {
    [super setUp];

    // Set-up code here.
}

- (void)tearDown {
    // Tear-down code here.

    [super tearDown];
}

- (void)testCustomStyleSort1 {
    AshtonHTMLWriter *writer = [[AshtonHTMLWriter alloc] init];
    NSArray *keys         = @[ @"-a", @"-b", @"a", @"b", @"c" ];
    NSArray *expectedKeys = @[ @"a", @"b", @"c", @"-a", @"-b" ];

    NSArray *sortedKeys = [writer performSelector:@selector(sortedStyleKeyArray:) withObject:keys];
    STAssertEqualObjects(sortedKeys, expectedKeys, @"Sort keys starting with - to the end");
}

- (void)testCustomStyleSort2 {
    AshtonHTMLWriter *writer = [[AshtonHTMLWriter alloc] init];
    NSArray *keys         = @[ @"-cocoa-font-features", @"font", @"text-align" ];
    NSArray *expectedKeys = @[ @"font", @"text-align", @"-cocoa-font-features" ];

    NSArray *sortedKeys = [writer performSelector:@selector(sortedStyleKeyArray:) withObject:keys];
    STAssertEqualObjects(sortedKeys, expectedKeys, @"Sort keys starting with - to the end");
}

@end
