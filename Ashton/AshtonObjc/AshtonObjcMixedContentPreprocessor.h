//
//  AshtonObjcMixedContentPreprocessor.h
//  Ashton
//
//  Created by Michael Schwarz on 15.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface AshtonObjcMixedContentPreprocessor: NSObject

- (NSString *)preprocessHTMLString:(NSString *)htmlString;

@end

NS_ASSUME_NONNULL_END
