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

Try Milk Now
------------

Wondering what it can do?
[Hit the playground!](http://pvande.github.com/Milk/playground.html)

Installation
------------

    npm install milk

Usage
-----

Milk is built for use both in CommonJS environments and in the browser (where
it will be exported as `window.Milk`).  The public API is deliberately simple:

### render

``` javascript
  Milk.render(template, data);            // => 'A rendered template'
  Milk.render(template, data, partials);  // => 'A rendered template'
```

The `render` method is the core of Milk. In its simplest form, it takes a
Mustache template string and a data object, returning the rendered template.
It also takes an optional third parameter, which can be either a hash of named
partial templates, or a function that takes a partial name and returns the
partial.

### partials

``` javascript
  Milk.partials = { ... };

  // equivalent to Milk.render(template, data, Milk.partials)
  Milk.render(template, data);
```

If your application's needs for partials are relatively simple, it may make
more sense to handle partial resolution globally.  To support this, your calls
to `render` will automatically fall back to using `Milk.partials` when you
don't supply explicit partial resolution.

### helpers

``` javascript
  Milk.helpers = { ... };  // will also work with an array

  // everything from Milk.helpers lives at the bottom of the context stack
  Milk.render(template, data);
```

Whether for internationalization or syntax highlighting, sometimes you'll find
yourself needing certain functions available everywhere in your templates.
To help enable this behavior, Milk.helpers acts as the baseline for your
context stack, providing a quick way to all the global data and functions you
need.

### escape

``` javascript
  Milk.escape('<tag type="evil">');  // => '&lt;tag type=&quot;evil&quot;&gt;'

  Milk.escape = function(str) { return str.split("").reverse().join("") };

  // Milk.escape is used to handle all escaped tags
  var template = "{{data}} is {{{data}}}";
  Milk.render(template, { "data": "reversed" });  // => "desrever is reversed"
```

`Milk.escape` is the function that Milk uses to handle escaped interpolation.
As such, you can use it (e.g. from lambdas) to perform the same escaping that
Milk does, or you can override it to change the behavior of escaped tags.

### VERSION

``` javascript
  Milk.VERSION  // => '1.2.0'
```

For when you absolutely must know what version of the library you're running.

Documentation
-------------

Milk itself is documented more completely at http://pvande.github.com/Milk 
(public API documentation is
[this bit](http://pvande.github.com/Milk#section-26)).

The Mustache templating language is documented at http://mustache.github.com.

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
