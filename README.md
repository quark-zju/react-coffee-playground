# [React Coffee Playground](http://quark-zju.github.io/react-coffee-playground)

Like [react-live-editor](https://github.com/joelburget/react-live-editor) but in [CoffeeScript](https://github.com/jashkenas/coffeescript).


## Rational

People write React in different languages, plain javascript, javascript with JSX, coffee script,
coffee script with JSX ...

I choose coffee because it requires less keystrokes:

```coffeescript
{svg, circle} = React.DOM

ThreeDots = React.createFactory React.createClass
  render: ->
    svg viewBox: '-2 -2 4 4',
      [0..2].map (x) ->
        circle cx: Math.sin(Math.PI * x / 1.5), cy: Math.cos(Math.PI * x / 1.5), r: 0.6

React.render ThreeDots(), mountNode

```

When creating new React components, a live editor is pretty useful. React.js official has live editors, 
but that's javascript. This project tries to fill the blank.


## Features

* `{div, span, p ... } = React.DOM` is done by the editor. So you can use them directly.
* Press [Tab] to active auto completion. The auto completer is stupid but practically useful.
* Serialize the code to the URL. So it can be shared without a central hosting server.
* JSX support thanks to [coffee-react-transform](https://github.com/jsdf/coffee-react-transform). Highlighting won't work though.


## Build

```bash
bundle && bundle exec rake
browser public/index.html
```


## Code Structure

The project looks like a Rails project. However it's not a dynamic Rails app but just some static files using Rake to build.
