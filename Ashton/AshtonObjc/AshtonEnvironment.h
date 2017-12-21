//
//  AshtonEnvironment.h
//  Ashton
//
//  Created by Michael Schwarz on 21.12.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//


#if TARGET_OS_IOS
@import UIKit;

@compatibility_alias ASHColor UIColor;
@compatibility_alias ASHFont UIFont;
@compatibility_alias ASHFontDescriptor UIFontDescriptor;

#define ASHFontDescriptorNameAttribute UIFontDescriptorNameAttribute
#define ASHFontDescriptorSymbolicTraits UIFontDescriptorSymbolicTraits
#define ASHFontDescriptorTraitBold UIFontDescriptorTraitBold
#define ASHFontDescriptorTraitItalic UIFontDescriptorTraitItalic

#elif TARGET_OS_MAC
@import AppKit;

@compatibility_alias ASHColor NSColor;
@compatibility_alias ASHFont NSFont;
@compatibility_alias ASHFontDescriptor NSFontDescriptor;

#define ASHFontDescriptorNameAttribute NSFontNameAttribute
#define ASHFontDescriptorSymbolicTraits NSFontDescriptorSymbolicTraits
#define ASHFontDescriptorTraitBold NSFontDescriptorTraitBold
#define ASHFontDescriptorTraitItalic NSFontDescriptorTraitItalic

#endif
