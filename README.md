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

## Sign in
Go to the root url:

    http://thimblsinging.fernandoguillen.info
    
Insert your **thimbl user account** and your **password** and press **login**, it will carry you to your *timeline* page.

## Show User

    http://thimblsinging.fernandoguillen.info/<thimbl_user>
    
Like:

    http://thimblsinging.fernandoguillen.info/fguillen@telekommunisten.org
    
If the server has already the info of this user *cached* then it will response with the *cached data*, if not the server will **fetch** the info of this users together with the info of every user he is *following*.

## Update Cached Info

Any time you can push in the **Update Now** link to update the info of this user.
    

# TODO

* better design.
* layout for mobile devices.
* Use the full *followings* lists to build a proper *known users* lists
* modifications of the personal details like: **bio**, ...
* Not update the an user's cache if it is less than X minutes old. (trying to avoid re-re-re-fetching)
* Detect links in messages.
* Support for flash messages
* Detect thimbl addresses in message texts.




