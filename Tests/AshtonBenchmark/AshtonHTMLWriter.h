#import <Foundation/Foundation.h>

@interface AshtonHTMLWriter : NSObject

+ (instancetype)sharedInstance;

- (NSString *)HTMLStringFromAttributedString:(NSAttributedString *)input;

@end
