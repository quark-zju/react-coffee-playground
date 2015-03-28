# Taken from facebook.github.io/react/js/live_editor.js, modified

{pre, textarea, div} = React.DOM

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
      indentUnit: 2
      smartIndent: false
      tabSize: 2
      indentWithTabs: false
      autofocus: true
      extraKeys:
        'Ctrl-Space': 'autocomplete'
        'Tab': (cm) ->
          if cm.somethingSelected()
            cm.indentSelection 'add'
          else
            cursor = cm.getCursor()
            if cm.getLine(cursor.line).length == cursor.ch
              cm.execCommand 'autocomplete'
            else
              cm.replaceSelection '  '
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
