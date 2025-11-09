---
layout: post
title: "Golang \"The system cannot find the path specified\" (on Windows)"
date: 2016-09-12 17:00:00 -0500
categories: Go
tags: [Golang]
author: Shaked Klein Orbach
image: /assets/images/windows-error.jpg
summary: |
  In the last few weeks I have been working on a small bot/crawler project. Basically, I had to communicate with Wikimedia's API to get a large portion of information and images. One of my client's requirements was to ensure that the filename contains information about the downloaded image.
redirect_from:
  - /golang-the-system-cannot-find-the-path-specified-on-windows
  - /golang-the-system-cannot-find-the-path-specified-on-windows.html
---

In the last few weeks I have been working on a small bot/crawler project. Basically, I had to communicate with Wikimedia's API to get a large portion of information and images. One of my client's requirements was to ensure that the filename contains information about the downloaded image, such as:

- Page ID.
- Page title.
- Width.
- Height
- Does the image have a license? If so, does it include a license URL?
- Does the image have copyrights?
- Does the image require permissions?
- Does the image have restrictions?

etc etc...

An example for a filename was supposed to be something like:

```
// length=216
$ LongPageId_AVeryLongTitleIn_HereMoreThan260Chars_w1057_h816_hasLicense_hasLicenseUrl_hasCredit_hasCopyrighted_hasPermission_hasRestrictions_hasUsageTerms_userBotCCAABBchill53a417796c777851003b3f2431e8eef5625ec15b.gif
```

The main reason for this requirement was because the client wanted to be able to filter images via command line, e.g:

```bash
$ ls -la /path/to/crawler-data/downloaded-images/ | grep -i issquare | wc -l
100
```

## Cross Platforms

While I am working on a Mac, my client used Windows and he wanted to be able to use this small "crawler" locally (mainly to reduce costs). Once I was done, and everything worked as expected both on Mac and Linux, my client got the following error:

!["The system cannot find the path specified"](/assets/images/windows-error.jpg "The system cannot find the path specified")

```
// length=284
panic: open C:\Users\main\git\src\bitbucket.org\Shaked\wiki-crawler\tmp\images_3\LongPageId_AVeryLongTitleIn_HereMoreThan260Chars_w1057_h816_hasLicense_hasLicenseUrl_hasCredit_hasCopyrighted_hasPermission_hasRestrictions_hasUsageTerms_userBotCCAABBchill53a417796c777851003b3f2431e8eef5625ec15b.gif: The system cannot find the path specified.
```

As I haven't used Windows for quite a while, I didn't consider the [Maximum Path Length Limitation on Windows](https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx#maxpath), which is `260`.

After some trial and error, I have found the problem and I had to look for another solution for my client in order to be able to filter the images, but without replacing the command line solution (nor using SQL queries). The solution was simple. I have renamed the files to `SHA1_PageTitle.Extension` and mapped it by using a .json file, e.g:

```json
{
  "SHA1_PageTitle.Extension": {
    "status": true,
    "err": null,
    "isSquare": false,
    "width": 421,
    "height": 367,
    "hasLicense": true,
    "hasLicenseUrl": true,
    "hasCredit": true,
    "isCopyrights": true,
    "hasPermission": true,
    "hasRestrictions": true,
    "hasUsageTerms": true,
    "user": "UserName",
    "sizeInKB": 27
  }
}
```

Then, the easiest thing to do was to use [jq](https://stedolan.github.io/jq/ "jq is a lightweight and flexible command-line JSON processor.") which  is a lightweight and flexible command-line JSON processor. Now just run:

```bash
$ cat /path/to/crawler-data/downloadedImages.json | jq 'keys | length'
100
```

