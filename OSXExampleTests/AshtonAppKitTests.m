#import "AshtonAppKitTests.h"
#import "AshtonAppKit.h"
#import "AshtonUtils.h"


@interface AshtonAppKit (Private)
- (NSArray *)arrayForColor:(NSColor *)color;
- (NSColor *)colorForArray:(NSArray *)input;
@end

@implementation AshtonAppKitTests {
    AshtonAppKit *ashton;
}

- (void)setUp {
    [super setUp];
    ashton = [[AshtonAppKit alloc] init];
}

- (void)tearDown {
    ashton = nil;
    [super tearDown];
}

- (void)assertArray:(NSArray *)actual equals:(NSArray *)expected or:(NSString *)message {
    NSUInteger count = [expected count];
    double accuracy = 0.00000001;
    for(NSUInteger i = 0; i < count; i++) {
        double expectedValue = [expected[i] floatValue];
        double actualValue = [actual[i] floatValue];
        XCTAssertEqualWithAccuracy(expectedValue, actualValue, accuracy, "assertArray");
    }
}

- (void)testColorConversion {
    NSColor *color;
    NSArray *array, *expectedArray;

    color = [NSColor colorWithCalibratedWhite:0.35 alpha:0.25];
    array = [ashton arrayForColor:color];
    expectedArray = @[ @(0.35), @(0.35), @(0.35), @(0.25) ];
    [self assertArray:array equals:expectedArray or:@"calibrated white failed"];

    color = [NSColor colorWithCalibratedRed:0.1 green:0.2 blue:0.3 alpha:0.4];
    array = [ashton arrayForColor:color];
    expectedArray = @[ @(0.1), @(0.2), @(0.3), @(0.4) ];
    [self assertArray:array equals:expectedArray or:@"calibrated rgb failed"];

    color = [NSColor windowBackgroundColor];
    // make sure this color can't be converted to RGB using the naive approach
    XCTAssertNil([color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]], @"converting windowBackgroundColor was too easy.");
    array = [ashton arrayForColor:color];
    expectedArray = @[ @(0.905882358551), @(0.905882358551), @(0.905882358551), @(1) ];
    [self assertArray:array equals:expectedArray or:@"windowBackgroundColor has changed"];
}

- (void)testFontLineHeights {
    CTFontRef ctFont = (__bridge CTFontRef)([AshtonUtils CTFontRefWithFamilyName:@"Palatino-Bold" postScriptName:@"Palatino" size:18.0 boldTrait:YES italicTrait:NO features:nil]);
    NSLayoutManager *lm = [NSLayoutManager new];
    CGFloat ctHeight = [lm defaultLineHeightForFont:(__bridge NSFont *)(ctFont)];
    NSFont *nsFont = [NSFont fontWithName:@"Palatino-Bold" size:18.0];
    CGFloat nsHeight  = [lm defaultLineHeightForFont:nsFont];
    XCTAssertEqual(ctHeight, nsHeight, @"Line heights are not equal");
}

@end
