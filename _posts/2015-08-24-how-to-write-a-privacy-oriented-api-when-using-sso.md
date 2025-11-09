---
layout: post
title: "How To Write A Privacy Oriented API When Using SSO"
date: 2015-08-24 00:57:00 -0500
categories: Privacy
tags: [Facebook, SSO, Security, API]
author: Shaked Klein Orbach
image: /assets/images/facebook-api/privacy.jpg
redirect_from:
  - /how-to-write-a-privacy-oriented-api-when-using-sso
  - /how-to-write-a-privacy-oriented-api-when-using-sso.html
---

### Description

I have been noticing that many applications tend to skip some important points while writing their APIs. In this post I will try to discuss some of those points.

### Exposure & Privacy

Usually, when we write APIs, we use a common data structure in order to be able to communicate as easy as possible with different services. For the sake of the examples, I will be using `JSON` but you can think about other data structures as well.

It seems, that many applications today tend to expose the same data by using the exact same data model that they use to manage their data. In my opinion, most of the time it is incorrect to share the same data model between the application and the actual exposed data. This problem can be solved, depending on the language, by different approaches, such as using a strict *serialized* object or by dividing responsibilities.

Serializing objects is very simple, it might fit when the application is small and its easy to understand what one change will cause to the entire application.

Having said that, sometimes, the application is growing or is already bigger and then it might be smart to divide responsibilities. This means that the User object will contain the entire data it requires while a JsonUser object will contain **only** the data we want to share through our public API.

### Social Networks

Today, it is very common to use social networks, or better saying, single sign on, to register users. It is indeed, in my opinion, a very useful and comfortable way to speed up the registration process while making sure that the user is, most probably, real.

One of the most common privacy issues I have encountered is that different application such as: Tinder, Hinge, Couchsurfing and more, tend to publish different type of user private information. You can read more about these issues in my previous posts:

- [Tinder Privacy Issues](/2013/11/23/tinder-privacy-issues/ "Tinder Privacy Issues")
- [Hinge Privacy Issues](/2015/07/08/hinge-privacy-issues/ "Hinge Privacy Issues")
- [Couchsurfing Privacy Issues](/2015/06/29/couchsurfing-privacy-issues/ "Couchsurfing Privacy Issues")

Together with the previous topic about "Exposure and Privacy", this can be solved by making sure that **only** the necessary fields are publicly exposed. There are many types of data the shouldn't be exposed, for example:

- Original Profile Ids: if we take Facebook as an example, it might be worth checking [App-scoped Ids](https://developers.facebook.com/docs/apps/for-business "App-scoped Ids") and making sure the original ones stay hidden. I would assume that most users wouldn't want to be reached even though they can be searched via name, common friends, photos and other different available data.
- Data that exposes if the user is or isn't using the application, data that exposes if the user is active. This might be changed from one application to another, see my post about [Hinge Privacy Issues](/2015/07/08/hinge-privacy-issues/ "Hinge Privacy Issues") for more information.
- Original Photo Ids: its very easy to find a Facebook profile by just having his photo id, just hit [https://www.facebook.com/photo.php?fbid={{FacebookPictureID}}](https://www.facebook.com/photo.php?fbid={{FacebookPictureID}}) while replacing `{{FacebookPictureID}}` with the relevant photo id. I know that this can be blocked by the user as well, but I think that the actual responsibility belongs to the company.
- GPS information, in case you haven't seen it before, GPS information [might expose your users exact location](http://blog.includesecurity.com/2014/02/how-i-was-able-to-track-location-of-any.html "How I was able to track the location of any Tinder user.").
- Email Addresses.
- Birthdays.
- [EXIF](https://en.wikipedia.org/wiki/Exchangeable_image_file_format "Exchangeable image file format") - Just make sure that its reset when using the user's photos.
- Full Names - depending on the application, I would suggest considering not exposing your users full name.

It's maybe worth mentioning that its not only about privacy but also about SPAM. If you expose your users email address, or their Facebook profile, they might be a victim of SPAM just because of they wanted to use the service that you are offering.

### Images

#### Search By Image

As you probably know, it is possible to search images via Google Images. This helps users to actually track your users. I am not sure how much can be done and if its worth your time, but it might worth changing the user's photos with a stamp or some other original idea by trying to help your users to be a bit more discreet.

#### Original URLs

Even though its hard to find a Facebook profile by having a Facebook photo URL, I would still recommend to use your own. My examples here talk about Facebook but at the same time it can be any other social network or SSO that might expose more information which your users wouldn't want to expose.

#### Loading Photos

Although this post talks mostly about privacy, I want to mention another issue I have seen in different application. Some applications tend to load all their users photos while directly even though it is not necessary. Please consider using [lazy loading](http://www.giftofspeed.com/lazy-load-images/) to load the photos when they are actually needed. This will boost your application and will be less annoying for the user.

