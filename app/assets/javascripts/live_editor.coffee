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
      smartIndent: true
      matchBrackets: true
      theme: 'ambiance'
      readOnly: @props.readOnly)
    @editor.on 'change', @handleChange

  componentDidUpdate: ->
    if @props.readOnly
      @editor.setValue @props.codeText

  handleChange: ->
    if !@props.readOnly
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
    renderCode: React.PropTypes.bool
    showCompiledJSTab: React.PropTypes.bool
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
    # Import React.DOM components, written in the 1st line coffeescript
    tokens = _.intersection(_(React.DOM).keys(), code.split(/[\s(]/))
    if tokens.length > 0
      # `var` is reserved in coffeescript, remove it
      code = "{#{tokens.toString().replace(/(var,|var$)/, '')}} = React.DOM;#{code}"
    @props.transformer code

  render: ->
    compiledCode = ''

    try
      compiledCode = @compileCode()

    CoffeeContent = CodeMirrorEditor
      key: 'coffee'
      onChange: @handleCodeChange
      className: 'playgroundStage'
      codeText: @state.code
      lineNumbers: @props.showLineNumbers

    div className: 'playground',
      div className: 'playground_code_wrapper',
        div className: 'playground_code', CoffeeContent
      div className: 'playground_preview',
        div ref: 'mount'

  componentDidMount: ->
    @executeCode()

  componentDidUpdate: (prevProps, prevState) ->
    # execute code only when the state's not being updated by switching tab
    # this avoids re-displaying the error, which comes after a certain delay
    if @props.transformer != prevProps.transformer || @state.code != prevState.code
      @executeCode()

  executeCode: ->
    mountNode = @refs.mount.getDOMNode()
    try
      React.unmountComponentAtNode mountNode
    try
      compiledCode = @compileCode()
      if @props.renderCode
        React.render CodeMirrorEditor(
          codeText: compiledCode
          readOnly: true
        ), mountNode
      else
        eval compiledCode
    catch err
      @setTimeout (->
        React.render(
          div className: 'playground_error',
            err.toString()
          mountNode
        )
      ), 100
