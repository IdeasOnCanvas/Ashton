MSAttributedStringSerialization
==========================

(De)serializes NSAttributedStrings on OS X, iOS 5 and iOS 6 as HTML.

## Usage

```objc
NSString *intermediateHTMLString = 
  [MSAttributedStringSerialization HTMLStringWithAttributedString:sourceAttributedString];

// Write intermediateHTMLString to file
// Read intermediateHTMLString from file

NSString *outputAttributedString =
  [MSAttributedStringSerialization attributedStringWithHTMLString:intermediateHTMLString];

[outputAttributedString isEqual:sourceAttributedString]; // true
```