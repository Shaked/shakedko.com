---
layout: post
title: "Hinge Privacy Issues"
date: 2015-07-08 18:37:00 -0500
categories: Privacy
tags: [Hinge, Security]
author: Shaked Klein Orbach
image: /assets/images/hinge/hinge-logo.png
summary: |
  [Hinge](http://hinge.co/) is another dating app same as Tinder, Match, OkCupid, JSwipe and more. The nice thing about Hinge is that its trying to match between relevant people. After exposing privacy issues with the [Tinder app](/2013/11/23/tinder-privacy-issues/), I decided to check each and every application that asks for personal information.
redirect_from:
  - /hinge-privacy-issues
  - /hinge-privacy-issues.html
---

### Description

[Hinge](http://hinge.co/ "Meet real people, through your real friends, in real life.") is another dating app same as Tinder, Match, OkCupid, JSwipe and more.

The nice thing about Hinge is that its trying to match between relevant people and not just any random person as happens on the applications mentioned above.

Unfortunately, lately it seems like people just don't put enough effort to make sure that there are no privacy issues in their applications. After exposing [privacy issues with the Tinder app](/2013/11/23/tinder-privacy-issues/ "Tinder Privacy Issues") almost 2 years ago and [Couchsurfing privacy issues](/2015/06/29/couchsurfing-privacy-issues/ "Couchsurfing privacy issues"), I decided to check each and every application that asks for any type of personal information, especially when it involves social media information such as Google, Facebook, Twitter and so on.

!["Hinge copyrights http://hinge.io"](/assets/images/hinge/hinge-logo-300x100.png "Hinge copyrights http://hinge.io")

<sub><sup>Copyrights [http://hinge.io](http://hinge.io "Hinge")</sup></sub>

### TL;DR

Hinge allows people to see their users' private information such as:

- **User's Facebook profile URL** - this means that with enough understanding people would be able to find Hinge users on Facebook and contact them.
- **Mutual friend's information** - apparently Hinge exposes different type of details about mutual friends. The worst thing is the friend's email address.
- **Finding who uses Hinge** - if one would like to know if his\her partner his using Hinge he\she would be able to do that by scanning the information Hinge exposes.

More information below.

### Requirement

In order to follow this article you might need to know [mitmproxy](http://mitmproxy.org/ "mitmproxy: a-man-in-the-middle proxy") - installation instructions are available on my previous [Tinder Privacy Issues](/2013/11/23/tinder-privacy-issues/ "Tinder Privacy Issues") post.

### The Problems

#### User's Facebook Profile ID\URL

[Hinge](https://itunes.apple.com/us/app/hinge/id595287172?mt=8 "Hinge for iOS") seems to expose the Facebook profile ID of users who logged-in with their Facebook accounts, meaning - each and every user.

##### How

After installing *mitmproxy* and setting up all the above you will have to follow those steps:

1. On your phone, open the target's profile.
2. On your desktop, search for the following URL: https://prod-hinge-mobileservices.herokuapp.com/api/v1/users/{{UserID}}/profile/{{ProfileID}}/?origin=potential_match&subject_fbid={{FacebookID}}

The Facebook ID above would represent the user's real Facebook ID which you can add to the following URL and see his profile on Facebook:

> https://www.facebook.com/profile.php?id={{FacebookID}}

You can also check the screenshot attached below.

#### Mutual Friend's Information

Although its not a big deal, some friends might **not** want to expose their email address and if they actually use Hinge. It seems like Hinge offers this information in it's HTTP response details.

##### How

Same as before:

1. On your phone, open the target's profile.
2. On your desktop, search for the following URL: https://prod-hinge-mobileservices.herokuapp.com/api/v1/users/{{UserID}}/profile/{{ProfileID}}/?origin=potential_match&subject_fbid={{FacebookID}}

Now look for *mutual_friends* and you would see your friend's information in case there is a mutual friend(s):

```json
"mutual_friends": [
    {
        "email": "email@address.com",
        "fb_username": "facebook.username",
        "fbid": "facebookid",
        "first_name": "firstname",
        "hinge_user": true,
        "last_name": "lastname",
        "main_picture": {
            "picture": "...",
            "source": "..."
        },
        "picture": "..."
    }
]
```

#### Facebook Friends on Hinge?

It seems like Hinge can tell you if a Facebook user was somehow registered in its database. It **doesn't** necessarily mean that the user uses or used Hinge as it might mean that the user is a mutual friend between 2 active users or more.

##### How

1. On your phone, open the target's profile.
2. On your desktop, search for the following URL: https://prod-hinge-mobileservices.herokuapp.com/api/v1/users/{{UserID}}/profile/{{ProfileID}}/?origin=potential_match&subject_fbid={{FacebookID}}
3. Change the {{FacebookID}} with another FacebookID and hit the URL again. If it user is not in their database, the following result will come back:

!["Hinge Facebook ID not found"](/assets/images/hinge/facebook-play-not-found.png "Hinge Facebook ID not found")

When the response returns with different data then you would have to look for the field *hinge_user*. In case its *true*, it means that the user exist in their database and is **or was** a valid user, I assume that the field *monthly_active* will be useful in that case.

!["An Hinge user"](/assets/images/hinge/active-user.png "An Hinge user")

In case the value is *false* then the user might have deleted his profile or was added passively and thats **my assumption**.

!["Not an Hinge user"](/assets/images/hinge/inactive-user.png "Not an Hinge user")

### Summary

It seems that privacy issues are coming back again and again. I believe that companies today don't focus on their users privacy as they assume that it cannot be seen. Even though Hinge is still not Tinder, I believe that they should fix those issues ASAP to make sure their users are 100% safe and cannot be bothered by SPAM or any other inconvenient issue.

The above was tested using Hinge for iOS version 2.1.3.

### Timeline

- June 14th - Sent an email mentioning all issues.
- July 8th - Didn't get **any** reply regarding those issues. Published new blog post.
- July 8th - After publishing the post I got Hinge's response saying that they are working to fix the problem. I haven't had the time to verify but I saw that there is already an update in the App Store.

