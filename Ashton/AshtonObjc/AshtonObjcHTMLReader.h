//
//  AshtonObjcHTMLReader.h
//  Ashton
//
//  Created by Michael Schwarz on 20.12.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AshtonObjcHTMLReader : NSObject

- (NSAttributedString *)decodeAttributedStringFromHTML:(NSString *)html;

@end
