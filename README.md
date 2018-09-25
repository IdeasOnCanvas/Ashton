# Ashton 

[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Platforms iOS, macOS](https://img.shields.io/badge/Platform-iOS%20|%20macOS-blue.svg "Platforms iOS, macOS")
![Language Swift](https://img.shields.io/badge/Language-Swift%204.2-green.svg "Swift 4.2")
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](LICENSE.md)
[![Build status](https://badge.buildkite.com/418f84ba1ee2d996d15acb9332cf231a0d174f679873cb60ce.svg)](https://buildkite.com/ideasoncanvas/ashton)

Ashton (<b>A</b>ttributed<b>S</b>tring<b>H</b>TML<b>T</b>ransformati<b>on</b>) is an iOS and macOS library for fast (both way) conversion of NSAttributedString` <--> HTML.
The library is used in MindNode 5 for persisting formatted strings.

## 2.0 Release

The latest release is a complete rewrite in Swift focusing on improved performance and functional backwards compatibility to Ashton 1.x.
The new codebase has a comprehensive test suite with test coverage >90% and additional tests against the legacy 1.0 output.

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
