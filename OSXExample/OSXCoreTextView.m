#import "OSXCoreTextView.h"
#import <CoreText/CoreText.h>

@implementation OSXCoreTextView

- (void)setAttributedString:(NSAttributedString *)attributedString {
    _attributedString = attributedString;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    if (self.attributedString == nil) return;
    
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

	CGContextSetTextMatrix(context, CGAffineTransformIdentity);

	// draw
	CTLineRef line = CTLineCreateWithAttributedString(CFBridgingRetain(self.attributedString));
	CGContextSetTextPosition(context, 10.0, 10.0);
	CTLineDraw(line, context);

	// clean up
	CFRelease(line);
}

@end
