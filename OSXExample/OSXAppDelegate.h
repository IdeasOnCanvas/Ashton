#import "OSXCoreTextView.h"

@interface OSXAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet OSXCoreTextView *coreTextView;
@property (nonatomic, assign) IBOutlet NSTextView *appKitTextView;

@end
