//
//  iOSTests.m
//  iOSTests
//
//  Created by Martin Schürrer on 31/10/13.
//
//

#import <XCTest/XCTest.h>
#import "AshtonUIKit.h"
#import <CoreGraphics/CoreGraphics.h>

@interface AshtonUIKit (Private)
- (NSArray *)arrayForColor:(UIColor *)color;
- (UIColor *)colorForArray:(NSArray *)input;
@end

@interface iOSTests : XCTestCase

@end

@implementation iOSTests {
    AshtonUIKit *ashton;
}

- (void)setUp {
    [super setUp];
    ashton = [[AshtonUIKit alloc] init];
}

- (void)tearDown
{
    ashton = nil;
    [super tearDown];
}

- (void)testUIDeviceWhiteColorSpaceColor
{
    NSArray *colorsToTest =  @[ UIColor.blackColor, // kCGColorSpaceGenericGray
                                UIColor.whiteColor, // kCGColorSpaceGenericGray
                                [UIColor colorWithWhite:0.5 alpha:0.7], // kCGColorSpaceGenericGray
                                UIColor.redColor, // kCGColorSpaceGenericRGB
                                [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:0.2] // kCGColorSpaceGenericRGB
                                ];

    for (UIColor *color in colorsToTest) {
        NSLog(@"%@", color);
        NSArray *ashtonArray = [ashton arrayForColor:color];
        NSArray *correctArray = [self getCorrectRGBAsForColor:color];
        NSLog(@"Ashton: %@", ashtonArray);
        NSLog(@"correct: %@", correctArray);
        for (NSUInteger i=0; i<3; i++) {
            XCTAssertEqualWithAccuracy([ashtonArray[i] doubleValue], [correctArray[i] doubleValue], 0.01, @"color differs");
        }
    }
}

- (NSArray *)getCorrectRGBAsForColor:(UIColor *)color {
    CGFloat components[4];
    [self getRGBAComponents:components forColor:color];
    return @[ @(components[0]), @(components[1]), @(components[2]), @(components[3]) ];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wenum-conversion"
// http://stackoverflow.com/a/14507509
- (void)getRGBAComponents:(CGFloat [4])components forColor:(UIColor *)color {
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char resultingPixel[4] = {0};
    CGContextRef context = CGBitmapContextCreate(&resultingPixel,
                                                 1,
                                                 1,
                                                 8,
                                                 4,
                                                 rgbColorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);

    CGFloat a = resultingPixel[3] / 255.0;
    CGFloat unpremultiply = (a != 0.0) ? 1.0 / a / 255.0 : 0.0;
    for (int component = 0; component < 3; component++) {
        components[component] = resultingPixel[component] * unpremultiply;
    }
    components[3] = a;
}
#pragma clang diagnostic pop

@end
