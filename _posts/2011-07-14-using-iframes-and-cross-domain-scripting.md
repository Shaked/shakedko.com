---
layout: post
title: "Using Iframes and Cross Domain Scripting"
date: 2011-07-14 23:44:00 -0500
categories: Javascript
tags: [cross domain, cross domain scripting, iframes, javascript iframes, web security]
author: Shaked Klein Orbach
redirect_from:
  - /using-iframes-and-cross-domain-scripting
  - /using-iframes-and-cross-domain-scripting.html
---

So I didn't write for a long time, and its about time to do that. I\`v
few subjects to talk about, but today I will share my thoughts about
iframes and cross domain scripting.

[Iframe](http://en.wikipedia.org/wiki/HTML_element#Frames "About frames") is
an old HTML element which lets you load another page inside your current
page. People say that iframes are old and useless for us, but I think
they wrong.

Why?

Sometimes we want to make things that seems impossible because of our
browsers security rules. There are lots of guides and tutorials about
cross domain scripting, and seems that some very good implementation in
few well known projects:

1.  ICQ On Site
2.  Meebo web toolbar
3.  Wibiya
4.  [Facebook](https://developers.facebook.com/docs/guides/canvas/ "Example from Facebook") (Application
    and such)
5.  [Google](http://www.google.com "Google's Products, e.g: gtalk")
    products

You may try and view those products source code, and... if you have
enough skill, and I\`m sure you do, you will notice that they are using
lots of ways to bypass cross domain scripting while trying to be as safe
as they can.

So the idea is to allow our customers to use our product while they
don't need to understand any programming code.The customers will just
have to add a piece of our code to their website and we will be able to
control it without any dependency on our customer. Lets just view some
examples:

Lets pretend that Facebook and Google are trying to create some kind of
chat integration. Facebook finally understood that GTalk is better then
Facebook Chat and they want to use GTalk instead.

1.  Before we start make sure you have some kind of web server on your
    computer \\ remote web server.
2.  We will have to define our [Hosts
    file](http://en.wikipedia.org/wiki/Hosts_(file) "Hosts File") and
    add two domains:

```
127.0.0.1 www.google1.com
127.0.0.1 www.facebook1.com
```

If you are using remote web server, don't forget to change 127.0.0.1 to your server's DNS.

3.  now lets create the following directories and files:

```
/frames/
/frames/google.com.html
/frames/facebook.com.html
/frames/default.com.html
```

My advice is creating two separate [Virtual
hosts](http://en.wikipedia.org/wiki/Virtual_hosting "Virtual Hosting") (Examples:
[Apache](http://httpd.apache.org/docs/2.0/vhosts/examples.html "Apache Virtual Hosts Examples"),
[IIS](http://www.simpledns.com/kb.aspx?kbid=1149 "IIS Virtual Host Examples")) so
you will feel this implementation as it real.

After creating local\\remote environment we can start use some code.
lets start from our "Parent" window, which will be Facebook.

You may view the demo
[Here](/assets/examples/frames/facebook.com.html "Frames Demo") or
[Download](/assets/files/frames.rar "Frames demo") it

