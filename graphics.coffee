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


this.LineDrawer = (gl) ->

  prog = shaderProgram(gl,
    """
    attribute vec2 pos;

    void main() {
      gl_Position = vec4(pos, 0, 1.0);
    }
    """,
    """
    precision mediump float;

    void main() {
      gl_FragColor = vec4(1, 0, 0, 1);
    }
    """)
  prog.pos_attr = gl.getAttribLocation(prog, "pos")

  buffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(8), gl.DYNAMIC_DRAW)
  gl.vertexAttribPointer(prog.pos_attr, 2, gl.FLOAT, false, 0, 0)

  drawLine = (x1, y1, x2, y2, width=0.01) ->
    dx = x2 - x1
    dy = y2 - y1
    d = dx * dx + dy * dy
    if d < 1e-8
      dx = 0.5 * width
      dy = 0
    else
      d = 0.5 * width / Math.sqrt(d)
      dx *= d
      dy *= d

    vertices = new Float32Array([
      x1 - dx - dy, y1 - dy + dx
      x1 - dx + dy, y1 - dy - dx
      x2 + dx - dy, y2 + dy + dx
      x2 + dx + dy, y2 + dy - dx
    ])


    gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
    gl.bufferSubData(gl.ARRAY_BUFFER, 0, vertices)

    gl.useProgram(prog)

    gl.enableVertexAttribArray(prog.pos_attr)
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
    gl.vertexAttribPointer(prog.pos_attr, 2, gl.FLOAT, false, 0, 0)

    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

  drawLine
