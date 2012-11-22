#import "MNAttributedStringUIKit.h"
#import <CoreText/CoreText.h>

@interface MNAttributedStringUIKit ()
@property (nonatomic, readonly) NSArray *attributesToPreserve;
@end

@implementation MNAttributedStringUIKit

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static MNAttributedStringUIKit *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MNAttributedStringUIKit alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        _attributesToPreserve = @[ @"link", @"strikthroughColor", @"underlineColor", @"verticalAlign" ];
    }
    return self;
}

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input {
    NSMutableAttributedString *output = [input mutableCopy];
    NSRange totalRange = NSMakeRange (0, input.length);
    [input enumerateAttributesInRange:totalRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithCapacity:[attrs count]];
        for (id attrName in attrs) {
            id attr = attrs[attrName];
            if ([attrName isEqual:NSParagraphStyleAttributeName]) {
                // produces: paragraph
                NSParagraphStyle *paragraphStyle = attr;
                NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];

                if (paragraphStyle.alignment == NSTextAlignmentLeft) attrDict[@"textAlignment"] = @"left";
                if (paragraphStyle.alignment == NSTextAlignmentRight) attrDict[@"textAlignment"] = @"right";
                if (paragraphStyle.alignment == NSTextAlignmentCenter) attrDict[@"textAlignment"] = @"center";
                newAttrs[@"paragraph"] = attrDict;
            }
            if ([attrName isEqual:NSFontAttributeName]) {
                // produces: font
                UIFont *font = attr;
                NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];

                CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
                CTFontSymbolicTraits symbolicTraits = CTFontGetSymbolicTraits(ctFont);
                if ((symbolicTraits & kCTFontTraitBold) == kCTFontTraitBold) attrDict[@"traitBold"] = @(YES);
                if ((symbolicTraits & kCTFontTraitItalic) == kCTFontTraitItalic) attrDict[@"traitItalic"] = @(YES);

                attrDict[@"pointSize"] = @(font.pointSize);
                attrDict[@"familyName"] = CFBridgingRelease(CTFontCopyName(ctFont, kCTFontFamilyNameKey));
                newAttrs[@"font"] = attrDict;
            }
            if ([attrName isEqual:NSUnderlineStyleAttributeName]) {
                // produces: underline
                if ([attr isEqual:@(NSUnderlineStyleSingle)]) newAttrs[@"underline"] = @"single";
            }
            if ([attrName isEqual:NSStrikethroughStyleAttributeName]) {
                // produces: strikthrough
                if ([attr isEqual:@(NSUnderlineStyleSingle)]) newAttrs[@"strikethrough"] = @"single";
            }
            if ([attrName isEqual:NSForegroundColorAttributeName]) {
                // produces: color
                newAttrs[@"color"] = [self arrayForColor:attr];
            }
        }
        // after going through all UIKit attributes copy back the preserved attributes, but only if they don't exist already
        // we don't want to overwrite settings that were assigned by UIKit with our preserved attributes
        for (id attrName in attrs) {
            id attr = attrs[attrName];
            if ([self.attributesToPreserve containsObject:attrName]) {
                if(!newAttrs[attrName]) newAttrs[attrName] = attr;
            }
        }
        [output setAttributes:newAttrs range:range];
    }];

    return output;
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
                if ([attr isEqual:@"double"]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                if ([attr isEqual:@"thick"]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
            }
            if ([attrName isEqual:@"strikethrough"]) {
                if ([attr isEqual:@"single"]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
                if ([attr isEqual:@"double"]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
                if ([attr isEqual:@"thick"]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
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
