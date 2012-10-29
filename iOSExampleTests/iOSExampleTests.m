#import "iOSExampleTests.h"
#import "MSAttributedStringSerialization.h"

@implementation iOSExampleTests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown {
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample {
    [MSAttributedStringSerialization HTMLStringWithAttributedString:[[NSAttributedString alloc] init]];
    STFail(@"Unit tests are not implemented yet in iOSExampleTests");
}

@end
