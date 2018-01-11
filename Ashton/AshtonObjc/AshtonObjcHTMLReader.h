//
//  AshtonObjcHTMLReader.h
//  Ashton
//
//  Created by Michael Schwarz on 20.12.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AshtonObjcHTMLReader : NSObject

- (nullable NSAttributedString *)decodeAttributedStringFromHTML:(nullable NSString *)html;

@end

NS_ASSUME_NONNULL_END
