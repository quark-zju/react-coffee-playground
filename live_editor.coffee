IS_MOBILE = navigator.userAgent.match(/Android/i) or navigator.userAgent.match(/webOS/i) or navigator.userAgent.match(/iPhone/i) or navigator.userAgent.match(/iPad/i) or navigator.userAgent.match(/iPod/i) or navigator.userAgent.match(/BlackBerry/i) or navigator.userAgent.match(/Windows Phone/i)

CodeMirrorEditor = React.createClass(
  displayName: 'CodeMirrorEditor'
  propTypes:
    lineNumbers: React.PropTypes.bool
    onChange: React.PropTypes.func
  getDefaultProps: ->
    { lineNumbers: false }
  componentDidMount: ->
    if IS_MOBILE
      return
    @editor = CodeMirror.fromTextArea(@refs.editor.getDOMNode(),
      mode: 'javascript'
      lineNumbers: @props.lineNumbers
      lineWrapping: true
      smartIndent: false
      matchBrackets: true
      theme: 'solarized-light'
      readOnly: @props.readOnly)
    @editor.on 'change', @handleChange
    return
  componentDidUpdate: ->
    if @props.readOnly
      @editor.setValue @props.codeText
    return
  handleChange: ->
    if !@props.readOnly
      @props.onChange and @props.onChange(@editor.getValue())
    return
  render: ->
    # wrap in a div to fully contain CodeMirror
    editor = undefined
    if IS_MOBILE
      editor = React.createElement('pre', { style: overflow: 'scroll' }, @props.codeText)
    else
      editor = React.createElement('textarea',
        ref: 'editor'
        defaultValue: @props.codeText)
    React.createElement 'div', {
      style: @props.style
      className: @props.className
    }, editor
)

selfCleaningTimeout =
  componentDidUpdate: ->
    clearTimeout @timeoutID
    return
  setTimeout: ->
    clearTimeout @timeoutID
    @timeoutID = setTimeout.apply(null, arguments)
    return
ReactPlayground = React.createClass(
  displayName: 'ReactPlayground'
  mixins: [ selfCleaningTimeout ]
  MODES:
    JSX: 'JSX'
    JS: 'JS'
  propTypes:
    codeText: React.PropTypes.string.isRequired
    transformer: React.PropTypes.func
    renderCode: React.PropTypes.bool
    showCompiledJSTab: React.PropTypes.bool
    showLineNumbers: React.PropTypes.bool
    editorTabTitle: React.PropTypes.string
  getDefaultProps: ->
    {
      transformer: (code) ->
        JSXTransformer.transform(code).code
      editorTabTitle: 'Live JSX Editor'
      showCompiledJSTab: true
      showLineNumbers: false
    }
  getInitialState: ->
    {
      mode: @MODES.JSX
      code: @props.codeText
    }
  handleCodeChange: (value) ->
    @setState code: value
    @executeCode()
    return
  handleCodeModeSwitch: (mode) ->
    @setState mode: mode
    return
  compileCode: ->
    @props.transformer @state.code
  render: ->
    isJS = @state.mode == @MODES.JS
    compiledCode = ''
    try
      compiledCode = @compileCode()
    catch err
    JSContent = React.createElement(CodeMirrorEditor,
      key: 'js'
      className: 'playgroundStage CodeMirror-readonly'
      onChange: @handleCodeChange
      codeText: compiledCode
      readOnly: true
      lineNumbers: @props.showLineNumbers)
    JSXContent = React.createElement(CodeMirrorEditor,
      key: 'jsx'
      onChange: @handleCodeChange
      className: 'playgroundStage'
      codeText: @state.code
      lineNumbers: @props.showLineNumbers)
    JSXTabClassName = 'playground-tab' + (if isJS then '' else ' playground-tab-active')
    JSTabClassName = 'playground-tab' + (if isJS then ' playground-tab-active' else '')
    JSTab = React.createElement('div', {
      className: JSTabClassName
      onClick: @handleCodeModeSwitch.bind(this, @MODES.JS)
    }, 'Compiled JS')
    JSXTab = React.createElement('div', {
      className: JSXTabClassName
      onClick: @handleCodeModeSwitch.bind(this, @MODES.JSX)
    }, @props.editorTabTitle)
    React.createElement 'div', { className: 'playground' }, React.createElement('div', null, JSXTab, @props.showCompiledJSTab and JSTab), React.createElement('div', { className: 'playgroundCode' }, if isJS then JSContent else JSXContent), React.createElement('div', { className: 'playgroundPreview' }, React.createElement('div', ref: 'mount'))
  componentDidMount: ->
    @executeCode()
    return
  componentDidUpdate: (prevProps, prevState) ->
    # execute code only when the state's not being updated by switching tab
    # this avoids re-displaying the error, which comes after a certain delay
    if @props.transformer != prevProps.transformer or @state.code != prevState.code
      @executeCode()
    return
  executeCode: ->
    mountNode = @refs.mount.getDOMNode()
    try
      React.unmountComponentAtNode mountNode
    catch e
    try
      compiledCode = @compileCode()
      if @props.renderCode
        React.render React.createElement(CodeMirrorEditor,
          codeText: compiledCode
          readOnly: true), mountNode
      else
        eval compiledCode
    catch err
      @setTimeout (->
        React.render React.createElement('div', { className: 'playgroundError' }, err.toString()), mountNode
        return
      ), 500
    return
)

# ---
# generated by js2coffee 2.0.1