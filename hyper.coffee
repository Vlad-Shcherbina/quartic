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

this.qqq = (alpha, beta) ->
  d = Math.cos(beta) / Math.sin(alpha)
  r = Math.sqrt((d + 1) * (d - 1))
  Math.atanh((d - 1) / r) * 2
