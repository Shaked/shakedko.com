---
layout: post
title: "Tinder Privacy Issues"
date: 2013-11-23 10:00:00 -0500
categories: Privacy
tags: [Tinder, Security]
author: Shaked Klein Orbach
redirect_from:
  - /tinder-privacy-issues
  - /tinder-privacy-issues.html
  - /2013/Nov/23/tinder-privacy-issues.html
---

## Description

Few months ago I heard about a dating application called [Tinder](http://gotinder.com "Tinder - Find out who likes you nearby").

The idea of the app is pretty straight forward and actually cool. Imagine going to a bar, you see someone you like and make your move, Tinder allows you in the comfort of your own home. All you need to do is look over pictures and shared interests and if you like what you see you mark the person as "liked", otherwise skip it and move on to the next. If both sides like each other, meaning there is a "match", the application allows you to talk amongst yourselves and take it from there.

## The Problem

As the idea of the app is nice and it can actually work, privacy is still an important thing. As a user of this app I wouldn't want that people to be able to just text me, bypassing the "like" mechanism and basically just SPAM or disturb and annoy me.

As my confidence in mobile applications security is still lacking, I felt I should look into this application, and this is what I found:

### Finding Facebook ID (using Tinder)

This method doesn't alway work, for the reason is because the way of finding the Facebook ID of a Tinder user dependence on his Facebook privacy settings (luckily at least this part still helps sometimes...)

#### How

##### Requirements

1. [man-in-the-middle proxy](http://mitmproxy.org/ "mitmproxy: a-man-in-the-middle proxy")
2. Tinder auth token
3. Tinder user ID
4. (Optional) REST client - I chose to do it the "spoiled" way using [Postman - REST client](https://chrome.google.com/webstore/detail/postman-rest-client/fdmmgilgnpjigdojojpjoooidkmcomcm?hl=en "Postman - Rest client") but you can do it even with CURL, it's up to you.

Install the proxy and set it to listen your iPhone data. You can use a [nice guide](http://blog.philippheckel.com/2013/07/05/how-to-sniff-the-whatsapp-password-from-your-android-phone-or-iphone/ "How to sniff the whatsapp password from your android phone or iphone") to actually install it for both iPhone and Android.

Once installed,  just start it:

    mitmproxy -p 8888

You can of course change the port and use another one and do the same for th HTTP proxy on your phone (everything is written in the guide and mitmproxy's website).

Then once you open the Tinder app you can see some headers which we are going to use later on:

!["mitmproxy - Tinder token"](/assets/images/tinder/mitmproxy-tinder-token-9.png "mitmproxy - Tinder token")

The Tinder token is basically your tinder authorization token.

After finding the token we need to find the user id. All you need to do is simply play with the app and once you see suggested people you can just pick one and look in the proxy to get his\her's ID. There are few ways to do that, I will pick one which is just using the user's picture:

!["mitmproxy - Tinder user ID"](/assets/images/tinder/mitmproxy-tinder-user-image-7.png "mitmproxy - Tinder user ID")

I have hidden my token and the person's ID as it is private of course.

Now moving on to the REST client. In order to find the Facebook ID of we will have to query Tinder to return us the user profile of the Tinder user that we have chosen above. We can do that by querying "https://api.gotinder.com/user/USER_ID" and sending the following headers:

    Authorization: Token token="TINDER TOKEN ID"
    Content-Type: application/json
    X-Auth-Token: TINDER TOKEN ID
    User-Agent: Tinder/2.2.2 (iPhone; iOS 7.0.2; Scale/2.00) (Optional)

The response is a JSON structured data which contains the user's information on Tinder along with the user's pictures and their Facebook photo ID:

     "photos": [{
          "url":"....",
          "processedFiles":[....],
          "extension": "jpg",
          "fbId": "FB PHOTO ID",
        }....}

We are going to use the FB PHOTO ID to get this user's profile by just appending it to the following Facebook URL:

    https://www.facebook.com/photo.php?fbid=FB PHOTO ID

As I wrote above, this method doesn't always work if the user's Facebook privacy is restricted though *different IDs might have different privacy settings!*

It should look like this:

!["Postman REST client - Facebook photo ID"](/assets/images/tinder/postman-rest-fb-photo-id-6.png "Postman REST client - Facebook photo ID")

!["Facebook photo by ID"](/assets/images/tinder/facebook-photo-by-id-5.png "Facebook photo by ID")

### The cherry - bypass the matching mechanism

Bypassing the matching mechanism requires you to have only the user's Facebook ID which you already know how to do as explained above or if it's someone you know you can just use their Facebook ID directly and skip the part of looking for it.

Tinder uses the numeric Facebook ID which can be find by querying Facebook's graph API, e.g:

[http://graph.facebook.com/markzuckerberg](http://graph.facebook.com/markzuckerberg "Facebook Graph API")

    {
       "id": "4",
       "name": "Mark Zuckerberg",
      "first_name": "Mark",
       "last_name": "Zuckerberg",
      "link": "http://www.facebook.com/zuck",
       "username": "zuck",
       "gender": "male",
      "locale": "en_US"
    }

Now that we found our "target" we can try to match it. This splits to two options:

1. Matching an existing Tinder user
2. Finding who has a user on Tinder and who doesn't

I think that it will be enough to explain the first in order to understand the second. Then how? Tinder API supports an option to choose two Facebook users and match between them. I am not sure that what I've found was made as part of the design but if you simply match yourself with another person you would be able **to bypass the tinder matching mechanism!*** So lets start:

When we match between two people we are be able to see that a PUT request is being made along with the auth headers mentioned above:

    https://api.gotinder.com/matchmaker

Together with the following parameters:

    {
        "facebook_id1": "FACEBOOK ID 1",
        "facebook_id2": "FACEBOOK ID 2",
        "message": "TINDER DEFAULT MESSAGE"
    }

Once we put our Facebook ID in the first parameter and another Facebook ID in the second we will be notified that our user was matched with another user and now we are be able to talk to them even though that person didn't want to talk to us.

I noticed while writing this post, that it seems that one can also collect the email account of Tinder & Facebook users by doing that:

!["Tinder user email"](/assets/images/tinder/postman-tinder-user-email-12.png "Tinder User Email")

## Summary

We should aim to know which private information is being exposed and if so it should be fixed. I hope Tinder will fix it ASAP.

The above was tested using Tinder version 2.2.2 and version 3.

## Last minute update...

While writing this blog post I was actually a victim of SPAM. I was added by some girl that luckily I could see her Facebook photo ID and check her Facebook, all of her friends profiles were created on October 15th 2013 while all of them contain very provocative pictures. I didn't want to publish their pictures as it might be offending for the real girls that are in the pictures.

### More can be found at:

[qz.com](http://qz.com/150839/dating-app-tinder-is-still-exposing-personal-information/)

[businessinsider](http://www.businessinsider.com/new-tinder-privacy-issues-2013-11)

[dailydot](http://www.dailydot.com/technology/tinder-matching-mechanism-bypass/)

[programmableweb](http://www.programmableweb.com/news/today-apis-myobs-erp-api/2013/11/27)

[globaldatinginsights](http://www.globaldatinginsights.com/27112013-tinder-security-issues-exposed-by-developer/)

[themarker.com](http://www.themarker.com/technation/1.2176673) (Hebrew)

[canaltech.com.br](http://canaltech.com.br/noticia/apps/Falha-no-Tinder-permite-que-usuarios-tenham-acesso-a-dados-pessoais-de-terceiros/) (Portuguese)
