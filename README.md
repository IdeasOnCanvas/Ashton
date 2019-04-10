# Ashton 

[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Platforms iOS, macOS](https://img.shields.io/badge/Platform-iOS%20|%20macOS-blue.svg "Platforms iOS, macOS")
![Language Swift](https://img.shields.io/badge/Language-Swift%204.2-green.svg "Swift 4.2")
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](LICENSE.md)
[![Build status](https://badge.buildkite.com/418f84ba1ee2d996d15acb9332cf231a0d174f679873cb60ce.svg)](https://buildkite.com/ideasoncanvas/ashton)

Ashton (<b>A</b>ttributed<b>S</b>tring<b>H</b>TML<b>T</b>ransformati<b>on</b>) is an iOS and macOS library for fast conversion of NSAttributedStrings into HTML, and back. Ashton is battle-tested and used in [MindNode 6](https://mindnode.com), for persisting formatted strings.

## 2.0 Release

The latest release is a complete rewrite in Swift focusing on improved performance and functional backwards compatibility to Ashton 1.x. The new codebase has a comprehensive test suite with a test coverage of > 90% and additional tests against the legacy 1.0 output. 

Find out more about the launch of Ashton 2.0 in our [Blog Post](https://ideasoncanvas.com/news/2019-04-10-optimizing-text-persistence).

## Supported Attributes

The following `NSAttributedString.Key` attributes are supported, when converting to `HTML`:
- [x] .backgroundColor (persisted as RGBA)
- [x] .foregroundColor (persisted as RGBA)
- [x] .underlineStyle (single, double, thick)
- [x] .underlineColor (persisted as RGBA)
- [x] .strikethroughColor (persisted as RGBA)
- [x] .strikethroughStyle (single, double, thick)
- [x] .font
- [x] .paragraphStyle (text alignment)
- [x] .baselineOffset
- [x] NSSuperScript
- [x] .link

## Supported HTML Tags & Attributes

As Ashton supports only tags which are necessary to persist the attributes mentioned above, not all HTML tags are supported when converting `HTML` --> `AttributedString`. Basically, Ashton converts an AttributedString into a concatenation of `span`, `p` and `a` tags with style attributes. 

Supported HTML Tags:
- [x] span
- [x] p
- [x] a
- [x] em
- [x] strong

The following style attribute keys are supported:
- [x] background-color
- [x] color
- [x] text-decoration
- [x] font
- [x] text-align
- [x] vertical-align
- [x] Additional custom attributes (-cocoa-strikethrough-color, -cocoa-underline-color, -cocoa-baseline-offset, -cocoa-vertical-align, -cocoa-font-postscriptname, -cocoa-underline, -cocoa-strikethrough, -cocoa-fontFeatures)

Colors have to be formatted as rgba like `rgba(0, 0, 0, 1.000000)`.

## Integration with Carthage

Add this line to your Cartfile.
```
github "IdeasOnCanvas/Ashton"
```

## Usage

### Encode HTML

```swift
let htmlString = Ashton.encode(attributedString)
```

### Decode NSAttributedString

```swift
let attributedString = Ashton.decode(htmlString)
```

## Example App

An example app can be found in the `/Example` directory. It can be used to test `NSAttributedString` -> HTML -> `NSAttributedString` roundtrips and also to extract the HTML representation of an `NSAttributedString.

![](README/exampleScreenshot.png)


## Credits

Ashton is brought to you by [IdeasOnCanvas GmbH](https://ideasoncanvas.com), the creator of [MindNode for iOS, macOS & watchOS](https://mindnode.com).
