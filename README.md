Ashton
==========================

Converts NSAttributedStrings between AppKit, CoreText, UIKit and HTML.

What crazy name is that?
------------------------
Not crazy at all: <b>A</b>ttributed<b>S</b>tring<b>H</b>TML<b>T</b>ransformati<b>on</b>.

What does it actually do?
-------------------------
Ashton has two parts

a) It can convert the attributes of a AppKit, CoreText or UIKit NSAttributedString to and from an intermediate cross-platform Ashton-specific representation. This allows us to convert e.g. AppKit -> Ashton intermediate -> CoreText.

b) It can convert between a NSAttributedString with intermediate attributes and HTML. This allows us to transfer a NSAttributedString between Mac and iOS.

<table>
  <tr>
    <th>AppKit Input</th>
    <th>Intermediate</th>
    <th>AppKit Output</th>
  </tr>
  <tr>
    <td><code>NSParagraphStyleAttributeName</code> with <code>textAlign</code></td>
    <td><pre>@"paragraph": @{ @"textAlignment":@"left|right|center" }</pre></td>
    <td><code>NSParagraphStyleAttributeName</code> with <code>textAlign</code></td>
  </tr>
  <tr>
    <td><code>NSFontAttributeName</code></td>
    <td><pre>@"font": @{ @"traitBold":@YES, @"traitItalic":@NO,
    @"features":@[@[@5, @1], @[@14, @1]],
    @"pointSize":@12, @"familyName":@"Helvetica" }</pre></td>
    <td><code>NSFontAttributeName</code></td>
  </tr>
  <tr>
    <td><code>NSSuperscriptAttributeName</code> with values <code>1</code> or <code>-1</code></td>
    <td><code>@"verticalAlign": @"super|sub"</code></td>
    <td><code>NSSuperscriptAttributeName</code></td>
  </tr>
  <tr>
    <td><code>NSUnderlineColorAttributeName</code></td>
    <td><code>@"underlineColor": @[@255, @0, @0, @1.0]</code></td>
    <td><code>NSUnderlineColorAttributeName</code></td>
  </tr>
  <tr>
    <td><code>NSStrikethroughStyleAttributeName</code></td>
    <td><code>@"strikethrough": @"single|thick|double"</code></td>
    <td><code>NSStrikethroughStyleAttributeName</code></td>
  </tr>
  <tr>
    <td><code>NSStrikethroughColorAttributeName</code></td>
    <td><code>@"strikethroughColor": @[@255, @0, @0, @1.0]</code></td>
    <td><code>NSStrikethroughColorAttributeName</code></td>
  </tr>
  <tr>
    <td><code>NSForegroundColorAttributeName</code></td>
    <td><code>@"color": @[@255, @0, @0, @1.0]</code></td>
    <td><code>NSForegroundColorAttributeName</code></td>
  </tr>
  <tr>
    <td><code>NSStrokeColorAttributeName</code></td>
    <td><code>@"color": @[@255, @0, @0, @1.0]</code></td>
    <td><code>NSForegroundColorAttributeName</code></td>
  </tr>
    <tr>
    <td><code>NSLinkAttributeName</code></td>
    <td><code>@"link": @"http://google.com/"</code></td>
    <td><code>NSLinkAttributeName</code></td>
  </tr>
</table>
