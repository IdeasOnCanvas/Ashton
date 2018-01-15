//
//  AshtonObjcMixedContentPreprocessor.h
//  Ashton
//
//  Created by Michael Schwarz on 15.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/// TBXML parser cannot handle html mixed content, therefore we have to preprocess it
/// mixedContent = "<html>test <strong>sample</strong></html>", will be processed to
/// "<html><wrapped>test </wrapped><strong><wrapped>sample</wrapped></strong></html>
@interface AshtonObjcMixedContentPreprocessor: NSObject

- (NSString *)preprocessHTMLString:(NSString *)htmlString;

@end

NS_ASSUME_NONNULL_END
