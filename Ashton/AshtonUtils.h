#import <Foundation/Foundation.h>

@interface AshtonUtils : NSObject

+ (id)CTFontRefWithFamilyName:(NSString *)familyName postScriptName:(NSString *)postScriptName size:(CGFloat)pointSize boldTrait:(BOOL)isBold italicTrait:(BOOL)isItalic features:(NSArray *)features;

+ (void)clearFontsCache;
+ (NSArray *)arrayForCGColor:(CGColorRef)color;


@end
