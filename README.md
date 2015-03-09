reflex
======

Web application framework for React

## Get Started

None of reflex is in npm yet, you need to install all required modules from
Github and `npm link` them.

This will soon change to use Github dependencies and as soon as we release an 0.1.rc1 and
submit to npm

Meanwhile, this is the way to get reflex up and running:

```
$ git clone https://github.com/redbadger/reflex-cli
$ git clone https://github.com/redbadger/reflex
$ git clone https://github.com/redbadger/generator-reflex
```

That gets you the three pieces, next we need to link `generator-reflex` and `reflex-cli`

```
$ cd generator-reflex && npm link
$ cd .. && cd reflex-cli
$ npm link generator-reflex
$ npm link
```

This should give you the `reflex` command. Finally, you can start a Reflex application using it

``
$ mkdir my-reflex-app
$ cd my-reflex-app
$ reflex init
$ npm link reflex
$ reflex s
```

And that's it, your app should be running on port 3000 now.
