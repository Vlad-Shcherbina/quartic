---
---
this.glFromCanvas = (canvas) ->
  devicePixelRatio = window.devicePixelRatio || 1;
  canvas.width = canvas.clientWidth * devicePixelRatio;
  canvas.height = canvas.clientHeight * devicePixelRatio;

  gl = canvas.getContext('webgl') or canvas.getContext('experimental-webgl')
  if not gl
    alert 'Unable to initialize WebGL.'
    return

  if GL_DEBUG
    console.log 'GL DEBUG'
    throwOnGlError = (err, funcName, args) ->
      throw WebGLDebugUtils.glEnumToString(err) + ' was caused by call to: ' + funcName
    validateNoneOfTheArgsAreUndefined = (funcName, args) ->
      for arg in args
        if args == undefined
          throw 'Undefined passed to gl.' + funcName
    gl = WebGLDebugUtils.makeDebugContext(
      gl, throwOnGlError, validateNoneOfTheArgsAreUndefined)
  gl


this.createAndFillBuffer = (gl, data) ->
  # data is Float32Array
  buffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
  gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
  return buffer


this.shaderProgram = (gl, vs, fs) ->
  prog = gl.createProgram()
  addShader = (type, source) ->
    s = gl.createShader(type)
    gl.shaderSource(s, source)
    gl.compileShader(s)
    if not gl.getShaderParameter(s, gl.COMPILE_STATUS)
      throw 'Could not compile ' + type + ' shader:\n\n' + gl.getShaderInfoLog(s)
    gl.attachShader(prog, s)
    return

  addShader(gl.VERTEX_SHADER, vs)
  addShader(gl.FRAGMENT_SHADER, fs)
  gl.linkProgram(prog)
  if not gl.getProgramParameter(prog, gl.LINK_STATUS)
    throw 'Could not link the shader program!'
  return prog
