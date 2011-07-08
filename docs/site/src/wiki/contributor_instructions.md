Hacking On Tir
=========

This is organized more like a FAQ than a guide, but it gives all the information
you probably need to hack on the Tir source code.  It talks about getting the
code, doing your first patch, coding guidelines, etc.  These aren't meant to be strict
rules but more guidelines to follow.

I want to hack on Tir.  How do I join?
=========

To get in on Tir you have to prove you can write code by writing some
code doing this:

* Follow the instructions in this document and get your git checkout working.
* Commit your changes to your repository when you think they're good.
* Then go find <a href="http://tir.mongrel2.org/rptview?rn=2">a ticket to do</a> and write code to fix it.
* Join the <a href="mailto:mongrel2@librelist.com">mongrel2@librelist.com</a> mailing list or join #mongrel2 on irc.freenode.org where we discuss Tir.
* Once you tell us about it, do a pull request or toss us a patch.
* Finally, one of us will check out your changes and see if they're good to pull.  If they are, and you want to get into the project, then just fix a few more bugs and we'll let you in.

Each of these steps is documented in this document, so just read it real quick and get a
good understanding of the project before you continue.



How do I find things to do?
=========

Look at the tickets on the [git repo](http://github.com/zedshaw/Tir/


Why can't I just access everything without logging in?
=========

We want to avoid spam and bots trolling our system and thrashing it or leaving junk around, so we
have a simple <a href="http://tir.mongrel2.org/login">anonymous login</a> captcha you can use.  It's a
minor inconvenience that helps us out a lot.  It also weeds out people who aren't smart enough or motivated
enough to actually help.



If I become a contributor how do I get mentioned?
=========

Core contributors get mentioned on the <a href="http://tir.mongrel2.org/home">home</a> page.
If I miss you just say something and I'll add you on.  I forget things sometimes.


How do you prioritize what to work on?
=========

We usually have a discussion on the <a href="mailto:mongrel2@librelist.com">mongrel2@librelist.com mailing list</a>
to figure out what to do next.


Who comes up with the vision and direction?
=========

Usually people who use Tir bring up the stuff they want and we add it.


What will get my contribution rejected?
=========

Generally if your change adds too much code, is poorly written, doesn't work
on multiple UNIX platforms, or doesn't have testing when it needs it.  Don't worry
though, we'll tell you how to clean it up and make it nice so that you learn
good style.  As a starting point, here's what we consider our style guide: 

What is your style guide?
=========

I'm not as familiar with Lua as I am with C, so here's my generic guidelines:

* Keep it small. There's no limit but the point of Tir is that you don't need much code.
* Keep your code clean and "flatter" with good use of white space for readability.
* Refactor common blocks of code or complex branches into functions, probably "static inline" is good.
* Aim for lines around 80 characters if possible.
* When in doubt, read and re-read the man page for function calls to make sure you got the error returns and parameters right.

In general the theme for Tir source is, "Don't code like an asshole."  If you write a piece of
code and you didn't consider how another person will use it, or just didn't care, then it'll probably
get rejected.


How do I learn more about Tir?
=========

Check out [the quick start](/wiki/quick_start.html) for the introduction.

