---
---
# Hyperbolic geometry utils

this.toMinkowskyHyperboloid = (x, y) ->
  new Float32Array([x, y, Math.sqrt(x*x + y*y + 1)])

this.hyperShiftXMat = (dx) ->
  mat = mat3.create()
  mat[8] = mat[0] = Math.cosh(dx)
  mat[2] = mat[6] = Math.sinh(dx)
  mat

this.hyperShiftYMat = (dy) ->
  mat = mat3.create()
  mat[8] = mat[4] = Math.cosh(dy)
  mat[5] = mat[7] = Math.sinh(dy)
  mat

# TODO: document
this.qqq = (alpha, beta) ->
  if alpha + beta >= Math.PI / 2
    throw "invalid angles"
  d = Math.cos(beta) / Math.sin(alpha)
  r = Math.sqrt((d + 1) * (d - 1))
  Math.atanh((d - 1) / r) * 2


this.midPoint = (pt1, pt2) ->
  d = vec3.create()
  vec3.add(d, pt1, pt2)
  q = Math.sqrt(d[2] * d[2] - d[0] * d[0] - d[1] * d[1])
  vec3.scale(d, d, 1.0 / q)
  d


# Spin basically represents polygon in a grid plus direction (as in HyperRogue).

this.makeStartSpin = (N, M) ->
  if N < 1 or M < 1 or 2 * (N + M) >= N * M
    throw "Invalid values of n and m"
  tri_w = qqq(Math.PI / N, Math.PI / M)

  p0 = toMinkowskyHyperboloid(0, 0)
  p1 = vec3.create()
  vec3.transformMat3(p1, p0, hyperShiftXMat(2 * tri_w))

  return {
    start: p0
    end: p1
    N: N
  }

this.flipSpin = (spin) ->
  return {
    start: spin.end
    end: spin.start
    N : spin.N
  }
