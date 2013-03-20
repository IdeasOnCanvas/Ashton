#import <Foundation/Foundation.h>

@interface AshtonUtils : NSObject

+ (id)CTFontRefWithName:(NSString *)familyName size:(CGFloat)pointSize boldTrait:(BOOL)isBold italicTrait:(BOOL)isItalic features:(NSArray *)features;

@end
