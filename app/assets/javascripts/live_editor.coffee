# Register our naive but complex hinter
((CodeMirror) ->
  getLineIndent = (line) ->
    match = /^\s+/.exec(line)
    if match
      match[0].length
    else
      0

  getParentLines = (cm) ->
    requiredIndent = 9e99
    strictParentLines = []
    parentLines = []
    [cm.getCursor().line..0].forEach (lineNo) ->
      line = cm.getLine(lineNo)
      if /^\s+$/.test(line)  # ignore blank lines
        return
      indent = getLineIndent(line)
      line = line.replace(/^\s+/, '')
      if indent <= requiredIndent
        parentLines.push line
      if indent < requiredIndent
        requiredIndent = indent
        strictParentLines.push line
    [strictParentLines, parentLines]

  isRenderContext = (strictParentLines) ->
    for line in strictParentLines
      if /^render.*>$/.test(line)
        return true
    false

  isReactComponentContext = (strictParentLines) ->
    strictParentLines.length == 2 &&
      /React\.(?:createClass|Component)/.test(strictParentLines[1])

  getAdaptiveHintWords = (cm) ->
    [strictParentLines, parentLines] = getParentLines(cm)
    console.log parentLines

    list = []

    # Collect defined variables
    for line in parentLines
      match = /(\w+)\s*=/.exec line
      if match
        list.push(match[1])

    # React class interface
    if isReactComponentContext(strictParentLines)
      list = list.concat [
        'mixins', 'statics', 'propTypes', 'contextTypes', 'childContextTypes',
        'getDefaultProps', 'getInitialState', 'getChildContext', 'render',
        'componentWillMount', 'componentDidMount', 'componentWillReceiveProps',
        'shouldComponentUpdate', 'componentWillUpdate', 'componentDidUpdate',
        'componentWillUnmount']

    # DOM element names, for render*
    if isRenderContext(strictParentLines)
      list = list.concat _.keys(React.DOM)

    list

  CodeMirror.registerHelper 'hint', 'react', (cm, options) ->
    getParentLines(cm)
    helpers = cm.getHelpers(cm.getCursor(), 'hint')
    words = options.words
    hintResults = []
    if helpers.length  # ex. [coffeehinter]
      for helper in helpers
        result = helper(cm, options)
        if result and result.list.length
          hintResults.push(result)
    words = getAdaptiveHintWords(cm)
    if words
      result = CodeMirror.hint.fromList(cm, words: words)
      if result && result.list.length
        hintResults.push(result)
    if hintResults.length
      # Merge hint results
      return _.foldl hintResults, (a, b) ->
        if _.isEqual(a.from, b.from) && _.isEqual(a.to, b.to)
          a.list = _.union(a.list, b.list)
        a
    # Last hope: "unreliable" anyword hinter
    if CodeMirror.hint.anyword
      result = CodeMirror.hint.anyword(cm, options)
      return result
    return
)(CodeMirror)



# Taken from facebook.github.io/react/js/live_editor.js, modified

{pre, textarea, div} = React.DOM

TAB_WIDTH = 2

CodeMirrorEditor = React.createFactory React.createClass
  displayName: 'CodeMirrorEditor'

  propTypes:
    lineNumbers: React.PropTypes.bool
    onChange: React.PropTypes.func

  getDefaultProps: ->
    { lineNumbers: false }

  componentDidMount: ->
    @editor = CodeMirror.fromTextArea(@refs.editor.getDOMNode(),
      lineNumbers: @props.lineNumbers
      lineWrapping: true
      matchBrackets: true
      theme: 'ambiance'
      indentUnit: TAB_WIDTH
      smartIndent: true
      tabSize: TAB_WIDTH
      indentWithTabs: false
      hintOptions:
        hint: CodeMirror.hint.react
        words: ['setState', 'state', 'props', 'forceUpdate', 'getInitialState',
          'findDOMNode', 'shouldComponentUpdate'].concat _.keys(React.DOM)
      autofocus: true
      extraKeys:
        'Ctrl-Space': 'autocomplete'
        'Tab': (cm) ->
          if cm.somethingSelected()
            cm.indentSelection 'add'
          else
            cursor = cm.getCursor()
            line = cm.getLine(cursor.line)
            if line.length == cursor.ch && !(/^\s*$/.test(line))
              cm.execCommand 'autocomplete'
            else
              cm.replaceSelection Array(TAB_WIDTH + 1).join(' ')
        'Backspace': (cm) ->
          cursor = cm.getCursor()
          line = cm.getLine(cursor.line)
          if line.length == cursor.ch && line.length >= TAB_WIDTH && /^\s+$/.test(line)
            cm.deleteH -TAB_WIDTH, 'char'
          else
            cm.deleteH -1, 'char'
      styleActiveLine: true)

    @editor.on 'change', @handleChange

  handleChange: ->
    @props.onChange?(@editor.getValue())

  render: ->
    # wrap in a div to fully contain CodeMirror
    div style: @props.style, className: @props.className,
      textarea ref: 'editor', defaultValue: @props.codeText


selfCleaningTimeout =
  componentDidUpdate: ->
    clearTimeout @timeoutID

  setTimeout: ->
    clearTimeout @timeoutID
    @timeoutID = setTimeout.apply(null, arguments)


@ReactPlayground = React.createFactory React.createClass
  displayName: 'ReactPlayground'

  mixins: [ selfCleaningTimeout ]

  propTypes:
    codeText: React.PropTypes.string.isRequired
    transformer: React.PropTypes.func
    showLineNumbers: React.PropTypes.bool

  getDefaultProps: ->
    transformer: (code) ->
      CoffeeScript.compile(CjsxTransform.transform(code))
    showLineNumbers: false

  getInitialState: ->
    code: @props.codeText

  handleCodeChange: (value) ->
    @setState code: value
    @executeCode()

  compileCode: ->
    code = @state.code
    @props.transformer code

  render: ->
    compiledCode = ''

    try
      compiledCode = @compileCode()

    CoffeeContent = CodeMirrorEditor
      onChange: @handleCodeChange
      className: 'playgroundStage'
      codeText: @state.code
      lineNumbers: @props.showLineNumbers

    div className: 'playground',
      div className: 'playground_code_wrapper',
        CoffeeContent
      div className: 'playground_preview',
        div ref: 'mount'

  componentDidMount: ->
    @executeCode()

  executeCode: ->
    mountNode = @refs.mount.getDOMNode()
    try
      React.unmountComponentAtNode mountNode

    # Make React.DOM variables (exclude keyword `var`) available in current scope.
    eval (_.without(_(React.DOM).keys(), 'var').map (name) ->
      "var #{name} = React.DOM.#{name};"
    ).join('')

    try
      compiledCode = @compileCode()
      eval compiledCode
    catch err
      window.err = err
      @setTimeout (=>
        React.render(
          div className: 'playground_error',
            err.toString()
          mountNode
        )
      ), 100
