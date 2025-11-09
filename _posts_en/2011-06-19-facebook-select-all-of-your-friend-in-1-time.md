---
layout: post
title: "Facebook: Select all of your friend in 1 time"
date: 2011-06-19 00:57:00 -0500
categories: Facebook
tags: [FB, fight spam, Javascript, privacy, Select all users]
author: Shaked Klein Orbach
summary: |
  I wrote a nice script to select all of your Facebook friends in one time. As my previous post, my wish is that Facebook will protect us as users and fight SPAM and keep our privacy settings.
redirect_from:
  - /facebook-select-all-of-your-friend-in-1-time
  - /facebook-select-all-of-your-friend-in-1-time.html
---

Hey again,

I wrote a nice script to select all of your Facebook friends in one
time.
As my previous post, my wish is that Facebook will protect us as users
and fight SPAM and keep our privacy settings.

**Updates**: added "fu" and "tu" params, see below.

```javascript
/**Code start
 *Change z=10 if you have less\more friends then 500
 *@param optional (int) "fu" - from what user to start
 *@param optional (int) "tu" - what user to end
 *Example: var z=10,fu=10,tu=3000
 *(will select only 2990 users, starting from user number 11)
 *
 *You may use the script without "fu" and "tu"
 *so it will run all over your users from 1 to LAST.
 */
javascript:var z=10,fu=10,tu=3000,w=window,d="document",wd=w[d];function l(){p=wd.getElementsByName("checkableitems[]");var le=("undefined"!=typeof tu)? tu:p.length;var st=("undefined"!=typeof fu)?fu:0;for(count=st;count<le;count++)setTimeout("p["+count+"].click()",10);alert("All of your friends selected, you may send your spam now")}var fbProfileBrowserListContainer=wd.getElementsByClassName("fbProfileBrowserListContainer"),f=wd.getElementById(fbProfileBrowserListContainer[1].parentNode.getAttribute("id"));function b(a){f.scrollTop+=1E7;a>=z?setTimeout("l()",1E3):setTimeout("b("+(a+1)+")",2E3)}setTimeout("b(1)",2E3);void(0);
//Code end
```

Full code: <http://pastebin.com/tkQAZSNY>

Using <http://closure-compiler.appspot.com/home> to compile

## How does it works:

1.  Create new event \\ go to existing event \\ Facebook application
2.  Open "Select Guests to Invite"
3.  Copy & Paste the link to your address bar
4.  Edit params by your needs. (see comments)

**
**

## Notes:

1.  Tested on Chrome & FireFox (Linux), Chrome (Windows)
2.  The script was tested on 500 friends.
3.  The script will automatically select **ALL** of your friends, it
    will scroll down for you.
4.  if you have lots of friends, increase "z=10" (you may try z=20 or
    more).
5.  **Wait till the script will select your friends, this may take 1-2
    minutes (Maybe less!)**.

**
**

## Results:

**Before**

![Facebook Friends Box](/assets/images/fballfriendsbox.png "Facebook Friends Box")


**After**

![Facebook Friends Box Selected](/assets/images/fballfriendsboxselected.png "Facebook Friends Box Selected")

**Your help:**If you tried another browser, found a problem or just
enjoying this script, I would like you to leave your comment(s).

