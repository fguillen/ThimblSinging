# ThimblSinging

Is a very simple web service for the [thimbl protocol](http://thimbl.net)

# Demo

[Thimbl Singing](http://thimblsinging.fernandoguillen.info)

# Install

    git clone git://github.com/fguillen/ThimblSinging.git
    cd ThimblSinging
    bundle install
    rackup
    open http://localhost:9292

# Instructions

## Active User
Go to the root url:

    http://thimblsinging.fernandoguillen.info
    
Insert your **thimbl user account** and press **active user**, it will carry you to the *show user* page.

## Show User

    http://thimblsinging.fernandoguillen.info/<thimbl_user>
    
Like:

    http://thimblsinging.fernandoguillen.info/fguillen@telekommunisten.org
    
If the server has already the info of this user *cached* then it will response with the *cached data*, if not the server will **fetch** the info of this users together with the info of every user he is *following*.

## Update Cached Info

Any time you can push in the **Update Now** link to update the info of this user.

## Post

Be sure the *active user* is your user, fill the textarea and the **Password** field and push **post**

## Follow

Be sure the *active user* is your user, fill the textarea and the **Password** field and push **post**

## Change Active User

Any time you can change the user active, fill the field and push **active user**.

# API

    http://thimblsinging.fernandoguillen.info/<thimbl_user>.json (GET)
    http://thimblsinging.fernandoguillen.info/<thimbl_user>/fetch (GET)
    http://thimblsinging.fernandoguillen.info/<thimbl_user>/post?text=<text>&password=<password> (POST)
    http://thimblsinging.fernandoguillen.info/<thimbl_user>/follow?nick=<nick>&address=<address>&password=<password> (POST)
    

# TODO

* unfollow option
* better design.
* layout for mobile devices.
* Use the full *followings* lists to build a proper *known users* lists
* The cache is not working well.. we should cache all the users and his followings but save the plans of the followings in diferents files, so we reuse cache and incress the *known users* list. If this works then the double .fetch is not needed.
* check if the user is a real user before cache it or show it


