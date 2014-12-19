---
---
global_transform = undefined

this.start = (canvas_id) ->
  canvas = document.getElementById(canvas_id)
  console.log canvas.clientWidth, canvas.width

  devicePixelRatio = window.devicePixelRatio || 1;
  canvas.width = canvas.clientWidth * devicePixelRatio;
  canvas.height = canvas.clientHeight * devicePixelRatio;

  global_transform = mat3.create()

  shift = (dx, dy) ->
    q = 2
    mat3.mul(
      global_transform,
      hyperShiftXMat(dx / canvas.clientWidth * q),
      global_transform)
    mat3.mul(
      global_transform,
      hyperShiftYMat(-dy / canvas.clientHeight * q),
      global_transform)

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
    attribute vec2 tex_coord;
    uniform mat3 mat;

    varying vec2 v_tex_coord;

    void main() {
      vec3 q = mat * pos;
      gl_Position = vec4(q, q.z + 1.0);
      v_tex_coord = tex_coord;
    }
    """,
    """
    precision mediump float;

    varying vec2 v_tex_coord;

    void main() {
      gl_FragColor = vec4(v_tex_coord, 1, 1);
    }
    """)
  prog.pos_attr = gl.getAttribLocation(prog, "pos")
  prog.tex_coord_attr = gl.getAttribLocation(prog, "tex_coord")
  prog.mat_uniform = gl.getUniformLocation(prog, "mat")

  N = 7
  M = 3
  if N < 1 or M < 1 or 2 * (N + M) >= N * M
    window.alert("Invalid values of n and m")
    return

  tri_w = qqq(Math.PI / N, Math.PI / M)
  tri_h = qqq(Math.PI / M, Math.PI / N)

  p0 = toMinkowskyHyperboloid(0, 0)
  p1 = vec3.create()
  vec3.transformMat3(p1, p0, hyperShiftXMat(tri_w))
  p2 = vec3.create()
  vec3.transformMat3(p2, p0, hyperShiftYMat(tri_h))

  edge_subdivisions = 4
  num_vertices = N * edge_subdivisions + 1 + 1
  vertices = new Float32Array(3 * num_vertices)
  tex_coords = new Float32Array(2 * num_vertices)
  origin = toMinkowskyHyperboloid(0, 0)

  idx = 0
  vertices.set(origin, idx * 3)
  tex_coords.set([0.5, 0.5], idx * 2)
  idx += 1

  for i in [0 .. N-1]
    for j in [0 .. edge_subdivisions - 1]
      m = mat3.create()
      mat3.rotate(m, m, 2 * i * Math.PI / N + Math.PI)
      mat3.mul(m, m, hyperShiftXMat(tri_w))
      mat3.mul(m, m, hyperShiftYMat(tri_h * (2.0 * j / edge_subdivisions - 1)))
      p = vec3.create()
      vec3.transformMat3(p, origin, m)
      vertices.set(p, idx * 3)
      tex_coords.set([
        (1 + Math.sin(3 * Math.PI * (i + j/edge_subdivisions) / N)) / 2,
        (1 + Math.cos(2 * Math.PI * (i + j/edge_subdivisions) / N)) / 2
        ], idx * 2)
      idx += 1

  # Repeat first vertex to close the loop.
  vertices.set(vertices.subarray(3, 3 + 3), idx * 3)
  tex_coords.set(tex_coords.subarray(2, 2 + 2), idx * 2)
  idx += 1
  if idx != num_vertices
    throw 'zzz'

  pos_buffer = createAndFillBuffer(gl, vertices)
  tex_coord_buffer = createAndFillBuffer(gl, tex_coords)

  gl.useProgram(prog)

  gl.enableVertexAttribArray(prog.pos_attr)
  gl.bindBuffer(gl.ARRAY_BUFFER, pos_buffer)
  gl.vertexAttribPointer(prog.pos_attr, 3, gl.FLOAT, false, 0, 0)

  gl.enableVertexAttribArray(prog.tex_coord_attr)
  gl.bindBuffer(gl.ARRAY_BUFFER, tex_coord_buffer)
  gl.vertexAttribPointer(prog.tex_coord_attr, 2, gl.FLOAT, false, 0, 0)


  render = () ->
    requestAnimationFrame(render)
    gl.viewport(0, 0, canvas.width, canvas.height)

    gl.clearColor(0.0, 0.0, 0.0, 1.0)
    gl.clear(gl.COLOR_BUFFER_BIT)

    draw_heptagon = (base_mat) ->
      mat = mat3.create()
      mat3.mul(mat, global_transform, base_mat)
      gl.uniformMatrix3fv(prog.mat_uniform, false, mat)
      gl.drawArrays(gl.TRIANGLE_FAN, 0, num_vertices)


    mat = mat3.create()
    draw_heptagon(mat)

    for i in [0..N-1]
      mat = mat3.create()
      mat3.rotate(mat, mat, 2 * i * Math.PI / N)

      for j in [1..3]
        mat3.rotate(mat, mat, 2 * (N//2 + j%2) * Math.PI / N)
        mat3.mul(mat, mat, hyperShiftXMat(-tri_w * 2))
        mat3.rotate(mat, mat, Math.PI)
        draw_heptagon(mat)

  render()


createAndFillBuffer = (gl, data) ->
  # data is Float32Array
  buffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
  gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
  return buffer


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
