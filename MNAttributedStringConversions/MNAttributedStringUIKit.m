#import "MNAttributedStringUIKit.h"
#import <CoreText/CoreText.h>

@interface MNAttributedStringUIKit ()
@property (nonatomic, readonly) NSArray *attributesToPreserve;
@end

@implementation MNAttributedStringUIKit

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static MNAttributedStringUIKit *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MNAttributedStringUIKit alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        _attributesToPreserve = @[ @"link", @"strikethrough", @"strikthroughColor", @"underline", @"underlineColor", @"verticalAlign" ];
    }
    return self;
}

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input {
    return [[NSAttributedString alloc] init];
}

- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input {
    NSMutableAttributedString *output = [input mutableCopy];
    NSRange totalRange = NSMakeRange (0, input.length);
    [input enumerateAttributesInRange:totalRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithCapacity:[attrs count]];
        for (NSString *attrName in attrs) {
            id attr = attrs[attrName];
            if ([attrName isEqual:@"paragraph"]) {
                // consumes: paragraph
                NSDictionary *attrDict = attr;
                NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

                if ([attrDict[@"textAlignment"] isEqual:@"left"])  paragraphStyle.alignment = NSTextAlignmentLeft;
                if ([attrDict[@"textAlignment"] isEqual:@"right"]) paragraphStyle.alignment = NSTextAlignmentRight;
                if ([attrDict[@"textAlignment"] isEqual:@"center"]) paragraphStyle.alignment = NSTextAlignmentCenter;

                newAttrs[NSParagraphStyleAttributeName] = paragraphStyle;
            }
            if ([attrName isEqual:@"font"]) {
                // consumes: font
                NSDictionary *attrDict = attr;
                CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes(CFBridgingRetain(@{
                                                                                                       (id)kCTFontNameAttribute: attrDict[@"familyName"],
                                                                                                       }));
                CTFontRef ctFont = CTFontCreateWithFontDescriptor(descriptor, [attrDict[@"pointSize"] doubleValue], NULL);

                CTFontSymbolicTraits symbolicTraits = 0; // using CTFontGetSymbolicTraits also makes CTFontCreateCopyWithSymbolicTraits fail
                if ([attrDict[@"traitBold"] isEqual:@(YES)]) symbolicTraits = symbolicTraits | kCTFontTraitBold;
                if ([attrDict[@"traitItalic"] isEqual:@(YES)]) symbolicTraits = symbolicTraits | kCTFontTraitItalic;
                if (symbolicTraits != 0) {
                    // Unfortunately CTFontCreateCopyWithSymbolicTraits returns NULL when there are no symbolicTraits (== 0)
                    // Is there a better way to detect "no" symbolic traits?
                    ctFont = CTFontCreateCopyWithSymbolicTraits(ctFont, 0.0, NULL, symbolicTraits, symbolicTraits);
                }

                // We need to construct a kCTFontPostScriptNameKey for the font with the given attributes
                NSString *fontName = CFBridgingRelease(CTFontCopyName(ctFont, kCTFontPostScriptNameKey));
                UIFont *font = [UIFont fontWithName:fontName size:[attrDict[@"pointSize"] doubleValue]];

                newAttrs[NSFontAttributeName] = font;
            }
            if ([attrName isEqual:@"underline"]) {
                // consumes: underline
                if ([attr isEqual:@"single"]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
            }
            if ([attrName isEqual:@"strikethrough"]) {
                if ([attr isEqual:@"single"]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
            }
            if ([attrName isEqual:@"color"]) {
                // consumes: color
                newAttrs[NSForegroundColorAttributeName] = [self colorForArray:attr];
            }
            if ([self.attributesToPreserve containsObject:attrName]) {
                newAttrs[attrName] = attr;
            }
        }
        [output setAttributes:newAttrs range:range];
    }];

    return output;
}

- (NSArray *)arrayForColor:(UIColor *)color {
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    return @[ @(red), @(green), @(blue), @(alpha) ];
}

- (UIColor *)colorForArray:(NSArray *)input {
    CGFloat red = [input[0] doubleValue], green = [input[1] doubleValue], blue = [input[2] doubleValue], alpha = [input[3] doubleValue];
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
