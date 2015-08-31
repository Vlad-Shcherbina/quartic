---
---
global_transform = undefined

drawLine = undefined

this.start = (canvas_id, N, M, plus_angle, minus_angle, num_iterations) ->
  canvas = document.getElementById(canvas_id)
  gl = glFromCanvas canvas

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

  if N < 1 or M < 1 or 2 * (N + M) >= N * M
    window.alert("Invalid values of n and m")
    return

  console.log(makeStartSpin(N, M))

  drawLine = LineDrawer(gl)

  curve = dragonCurve(num_iterations)
  curve = dragonCurve(num_iterations)

  render_frame = () ->
    requestAnimationFrame(render_frame)
    gl.viewport(0, 0, canvas.width, canvas.height)

    gl.clearColor(0.0, 0.0, 0.0, 1.0)
    gl.clear(gl.COLOR_BUFFER_BIT)

    drawCurve(curve, makeStartSpin(N, M), plus_angle, minus_angle, global_transform)

    # start_spin = makeStartSpin(N, M)
    # drawSpin(start_spin, global_transform)

    # s2 = flipSpin(start_spin)
    # s2 = rotateSpin(s2, 1)
    # drawSpin(s2, global_transform)
    # drawSpin(flipSpin(start_spin), global_transform)

  render_frame()


dragonCurve = (num_iterations) ->
  s = 'x'
  for _ in [1..num_iterations]
    s = s.replace(/x/g, 'xF+t')
    s = s.replace(/y/g, 'xF-y')
    s = s.replace(/t/g, 'y')
  s = s.replace(/x/g, '')
  s = s.replace(/y/g, '')
  s += 'F'
  s


drawCurve = (logo_commands, start_spin, plus_angle, minus_angle, global_transform) ->
  spin = start_spin
  for c in logo_commands
    if c == 'F'
      drawSpin(spin, global_transform)
      spin = flipSpin(spin)
      drawSpin(spin, global_transform)
    else if c == '+'
      spin = rotateSpin(spin, plus_angle)
    else if c == '-'
      spin = rotateSpin(spin, minus_angle)
    else
      console.assert(false, c)


drawSpin = (spin, global_transform) ->
  start = vec3.create()
  end = vec3.create()
  vec3.transformMat3(start, spin.start, global_transform)
  vec3.transformMat3(end, midPoint(spin.start, spin.end), global_transform)

  x1 = start[0] / (start[2] + 1)
  y1 = start[1] / (start[2] + 1)

  x2 = end[0] / (end[2] + 1)
  y2 = end[1] / (end[2] + 1)

  dx = x2 - x1
  dy = y2 - y1

  drawLine(x1, y1, x2, y2)
  drawLine(
    x1 + 0.8 * dx + 0.15 * dy, y1 + 0.8 * dy - 0.15 * dx
    x1 + 0.8 * dx - 0.15 * dy, y1 + 0.8 * dy + 0.15 * dx)
