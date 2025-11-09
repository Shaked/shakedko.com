---
layout: post
title: "Couchsurfing Privacy Issues"
date: 2015-06-29 10:19:00 -0500
categories: Privacy
tags: [Couchsurfing, Security]
author: Shaked Klein Orbach
redirect_from:
  - /couchsurfing-privacy-issues
  - /couchsurfing-privacy-issues.html
---

### Description

[Couchsurfing](https://www.couchsurfing.com/ "Stay with locals instead of at hotels") is one of the best products I have used in the last couple of years. It helped me to meet many people from all over the world, to host them or surf their couch and I am very thankful for that!

Privacy is an important thing. After exposing [privacy issues with the Tinder app](/2013/11/23/tinder-privacy-issues/ "Tinder Privacy Issues") almost 2 years ago, I have started to doubt more and more different applications that require my personal information.

### TL;DR

Couchsurfing allows people to see their users' private information such as:

- **User's Facebook profile URL** - this means that with enough understanding people would be able to find Couchsurfing users on Facebook and contact them.
- **Emergency Contact Details** - Although Couchsurfing promises that this information is **only** available for administrators, it exposes it to everyone. This means that if you fill up this form people would be able to see this information and use it (see screenshot bellow).

More information below.

!["Filled-in emergency contact details form"](/assets/images/couchsurfing/filled-in-emergency-contact-details-form.png "Filled-in emergency contact details form")



### Requirement

In order to follow this article you might need to know [mitmproxy](http://mitmproxy.org/ "mitmproxy: a-man-in-the-middle proxy") - installation instructions are available on my previous [Tinder Privacy Issues](/2013/11/23/tinder-privacy-issues/ "Tinder Privacy Issues") post.

### The Problems

#### User's Facebook Profile URL

The [Couchsurfing app](https://itunes.apple.com/us/app/couchsurfing-travel-app/id525642917?mt=8 "Couchsurfing app for iOS") seems to expose the Facebook profile of users who logged-in with their Facebook accounts.

##### How

After installing *mitmproxy* and setting up all the above you will have to follow those steps:

1. On your phone, open the target's profile.
2. On your desktop, search for the following URL: https://hapi.couchsurfing.com/api/v2/users/{{user-id}}
3. On the *response* tab look for *facebookProfileUrl* (see screenshot below).

!["Couchsurfing Facebook URL exposed"](/assets/images/couchsurfing/facebook-url-exposed.png "Couchsurfing Facebook URL exposed")

#### Emergency Contact Details

On Couchsurfing's website a user can fill-in a form to write down who should be his emergency contact. On the form it says:

>Emergency Contact information can ONLY be seen by administrators. It will be used if we need to get in touch with someone other than you in case of emergency. This could be a family member or close friend. Please include name, relation, phone number and email address.

It seems like this information can be seen by **ANYONE**.

##### How

1. On your phone, open the target's profile.
2. On your desktop, search for the following URL: https://hapi.couchsurfing.com/api/v2/users/{{user-id}}
3. On the *response* tab look for *emergencyContactInfo* (see screenshots below).

Using the form from the picture above it will be possible to see the detail in the HTTP response:


!["Filled-in emergency contact details response"](/assets/images/couchsurfing/filled-in-emergency-contact-details-response.png "Filled-in emergency contact details response")

### Summary

I am not sure if Couchsurfing's privacy issues are critical as Tinder's but in my opinion those are problems that should be fixed as I wouldn't want people to find my Facebook profile and SPAM or annoy me. Having said that, I think that promising your users a safe service requires the company to put more cautious and be as responsible as it claims to be.

The above was tested using Couchsurfing for iOS version 3.4.

### Timeline

- May 20th - Sent an email mentioning the Facebook profile URL issue - No reply, was not fixed.
- June 14th - Sent another email mentioning both issues.
- June 29th - Didn't get **any** reply regarding those issues. Published new blog post.

