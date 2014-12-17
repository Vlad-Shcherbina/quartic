---
---
global_transform = undefined

this.start = (canvas_id) ->
  canvas = document.getElementById(canvas_id)

  global_transform = mat3.create()

  shift = (dx, dy) ->
    q = 2
    mat3.mul(global_transform, hyperShiftXMat(dx / canvas.width * q), global_transform)
    mat3.mul(global_transform, hyperShiftYMat(-dy / canvas.height * q), global_transform)

  prev_touch_x = 0
  prev_touch_y = 0
  canvas.addEventListener('touchstart', (event) ->
    if event.targetTouches.length != 1
      return
    event.preventDefault();
    t = event.targetTouches[0]
    prev_touch_x = t.pageX
    prev_touch_y = t.pageY
  , false)
  canvas.addEventListener('touchmove', (event) ->
    if event.targetTouches.length != 1
      return
    event.preventDefault();
    t = event.targetTouches[0]
    dx = t.pageX - prev_touch_x
    dy = t.pageY - prev_touch_y
    prev_touch_x += dx
    prev_touch_y += dy
    shift(dx, dy)
  , false)

  canvas.addEventListener('mousemove', (event) ->
    # TODO: using which in mousemove is wrong, it should be tracked
    # in global mouseup and mousedown handlers.
    if event.which != 1
     return
    dx = event.movementX
    dy = event.movementY
    shift(dx, dy)
  , false)


  gl = canvas.getContext("webgl") or canvas.getContext("experimental-webgl")
  if not gl
    alert "Unable to initialize WebGL."
    return

  prog = shaderProgram(gl,
    """
    attribute vec3 pos;
    uniform mat3 mat;
    void main() {
      vec3 q = mat * pos;
      gl_Position = vec4(q, q.z + 1.0);
    }
    """,
    """
    void main() {
      gl_FragColor = vec4(1, 1, 0, 1);
    }
    """)
  gl.useProgram(prog)



  tri_w = qqq(Math.PI / 7, Math.PI / 3)
  tri_h = qqq(Math.PI / 3, Math.PI / 7)

  p0 = toMinkowskyHyperboloid(0, 0)
  p1 = vec3.create()
  vec3.transformMat3(p1, p0, hyperShiftXMat(tri_w))
  p2 = vec3.create()
  vec3.transformMat3(p2, p0, hyperShiftYMat(tri_h))

  vertices = new Float32Array(3 * 3)
  vertices.set(p0, 0)
  vertices.set(p1, 3)
  vertices.set(p2, 6)

  buffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
  gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW)
  prog.pos_attr = gl.getAttribLocation(prog, "pos")
  prog.mat_uniform = gl.getUniformLocation(prog, "mat")
  gl.enableVertexAttribArray(prog.pos_attr)
  gl.vertexAttribPointer(prog.pos_attr, 3, gl.FLOAT, false, 0, 0)

  render = () ->
    requestAnimationFrame(render)
    gl.viewport(0, 0, canvas.width, canvas.height)

    gl.clearColor(0.0, 0.0, 0.0, 1.0)
    gl.clear(gl.COLOR_BUFFER_BIT)

    draw_heptagon = (base_mat) ->
      mat = mat3.create()
      for i in [0..6]
        mat3.mul(mat, global_transform, base_mat)
        mat3.rotate(mat, mat, 2 * i * Math.PI / 7)
        mat3.mul(mat, mat, hyperShiftXMat(-tri_w))

        gl.uniformMatrix3fv(prog.mat_uniform, false, mat)

        gl.drawArrays(gl.TRIANGLES, 0, 3)

    mat = mat3.create()
    draw_heptagon(mat)

    for i in [0..6]
      mat = mat3.create()
      mat3.rotate(mat, mat, 2 * i * Math.PI / 7)

      for j in [1..5]
        mat3.rotate(mat, mat, 2 * (3 + j % 2) * Math.PI / 7)
        mat3.mul(mat, mat, hyperShiftXMat(-tri_w * 2))
        mat3.rotate(mat, mat, Math.PI)
        draw_heptagon(mat)


  render()


shaderProgram = (gl, vs, fs) ->
  prog = gl.createProgram()
  addShader = (type, source) ->
    s = gl.createShader(type)
    gl.shaderSource(s, source)
    gl.compileShader(s)
    if not gl.getShaderParameter(s, gl.COMPILE_STATUS)
      throw "Could not compile " + type + " shader:\n\n" + gl.getShaderInfoLog(s)
    gl.attachShader(prog, s)
    return

  addShader(gl.VERTEX_SHADER, vs)
  addShader(gl.FRAGMENT_SHADER, fs)
  gl.linkProgram(prog)
  if not gl.getProgramParameter(prog, gl.LINK_STATUS)
    throw "Could not link the shader program!"
  return prog
