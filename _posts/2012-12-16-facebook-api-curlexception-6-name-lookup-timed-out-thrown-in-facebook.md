---
layout: post
title: "Facebook API \"CurlException: 6: name lookup timed out thrown in Facebook"
date: 2012-12-16 00:51:00 -0500
categories: Facebook
tags: ["CurlException: 6", facebook curl, Graph API, Development]
author: Shaked Klein Orbach
redirect_from:
  - /facebook-api-curlexception-6-name-lookup-timed-out-thrown-in-facebook
  - /facebook-api-curlexception-6-name-lookup-timed-out-thrown-in-facebook.html
---

## Description

I am working on my Facebook app which I already mentioned before but
maybe didn't publish a direct link yet:
<https://www.staytunedapp.com> as it is still in a beta mode.

I had an issue with Facebook in the last few days\\week while seeing an
exception on my development server:

> **CurlException: 6: name lookup timed out, referer: ...**

## Suggested solution

I looked for a solution and the only one I have found was changing the
CURL timeout.

1.  Open Facebook PHP SDK path/base\_facebook.php
2.  Go to line 134
3.  Change *CURLOPT\_CONNECTTIMEOUT*=10 to *CURLOPT\_CONNECTTIMEOUT*=30 or more (30 worked for me)



## Links

[http://milkcodes.blogspot.co.il/2010/12/php-fatal-error-uncaught-curlexception.html](http://milkcodes.blogspot.co.il/2010/12/php-fatal-error-uncaught-curlexception.html%20%20 "PHP Fatal error: Uncaught CurlException: 6: name lookup timed out thrown in Facebook")

<http://stackoverflow.com/questions/5114597/how-to-solve-problem-of-curlexception-6-name-lookup-time-out-error-in-facebook>



Enjoy

