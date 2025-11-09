---
layout: post
title: "Introducing Go mobile detect package"
date: 2014-02-12 00:00:00 -0500
categories: Go
tags: [Golang, gomobiledetect, packages]
author: Shaked Klein Orbach
redirect_from:
  - /introducing-go-mobile-detect-package
  - /introducing-go-mobile-detect-package.html
---

## Description

Few months ago I have started to look into [Go](http://golang.org/ "Golang") and decided to give it a try. As part of my learning curve I have decided to contribute and help others with things there are missing or not completely finished.

One of the things that I have found useful contributing to was a mobile\device package detector as you may find implemented in many other languages. I have imported [MobileDetect](http://www.mobiledetect.net "Mobile Detect") which is a well known and maintained PHP library to [Gomobiledetect](https://github.com/Shaked/gomobiledetect "Gomobiledetect - Github")

### Usage

The usage is really simple and straightforward and can be done in different ways:

Code sample:

```go
import "github.com/Shaked/gomobiledetect"
//code here
func handler(w http.ResponseWriter, r *http.Request) {
    detect := gomobiledetect.NewMobileDetect(r, nil)
    if detect.IsMobile() {
        // do some mobile stuff
    }
    if detect.IsTablet() {
        // do some tablet stuff
    }
    deviceProperty := "iPhone"
    if detect.VersionFloat(deviceProperty) > 6 {
        // do something with iPhone v6
    }
}
```

More examples are available in the [Github repository](https://github.com/Shaked/gomobiledetect/tree/master/examples "Gomobiledetect examples")

### Summary

The feeling of contributing and helping the community to grow is great and I hope I will have the ability to keep doing that. Feel free to contribute to Gomobiledetect, use and enjoy it.

