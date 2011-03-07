Milk
====

      Idly the man scrawled quill along page.  It was early yet, but his day
    had scarcely begun.  Great sheaves of nearly identical work sat about his
    desk as the clock clicked slowly to itself.  One by one, new pages joined
    the ranks, permeated with the smell of roasted beans as the pen drew
    coffee as often as ink.
      Exhausted, he collapsed atop his work in a fitful doze.  Images began to
    invade his unconscious mind, of flight and fancy, and jubilant impropriety.
    Then just as suddenly as he had slept, he woke, the image of a small child
    wearing a big smile and a heavy coat of Milk on his upper lip startling him
    back to alertness.
      He saw clearly, as he looked across his paper-strewn desk, that the task
    could be changed – and for once, it looked like fun.

Milk is a [spec-conforming](https://github.com/mustache/spec) (v1.1+λ)
implementation of the [Mustache](http://mustache.github.com) templating
language, written in [CoffeeScript](http://coffeescript.com).  Templates can be
rendered server-side (through Node.js or any other CommonJS platform), or,
since CoffeeScript compiles to Javascript, on the client-side in the browser
of your choice.

Installation
------------

    npm install milk

Usage
-----

In the browser, Milk will automatically create a new global variable,
`window.Milk`; in a CommonJS environment, you'll probably want to declare this
yourself.

    var Milk = require('milk');

This variable has one method, `Milk#render`.  This method is completely
stateless, so parallel calls won't interfere.  You may call this method in a
couple of ways...

    var template = "A {{string}}...";
    var data     = { string: "template" };

    Milk.render(template, data); # => "A template..."

    template     = "A {{> partial}}..."
    var partials = { partial: 'sub-{{string}}' }
    Milk.render(template, data, partials); # => "A sub-template..."

More details about the Mustache language can be found at
http://mustache.github.com.

Copyright
---------

Copyright (c) 2011 Pieter van de Bruggen.

(The GIFT License, v2)

Permission is hereby granted to use this software and/or its source code for
whatever purpose you should choose.  Seriously, go nuts. Use it to build your
family CMS, your incredibly popular online text adventure, or to mass-produce
Constitutions for North African countries.

I don't care, it's yours.  Change the name on it if you want -- in fact, if
you start significantly changing what it does, I'd rather you did!  Make it
your own little work of art, complete with a stylish flowing signature in the
corner. All I really did was give you the canvas.  And my blessing.

    Know always right from wrong, and let others see your good works.
