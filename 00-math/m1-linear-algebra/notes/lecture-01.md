# M1 Lecture-01 - The geometry of Linear Equations

**Date:** 5/10/2026
**Resource:** Gilbert Strang - Linear Algebra

## Main Idea

Ax = b can be read in two ways:

1. Row capture: (row by row) - each row is is a geometric dhape in space - lines that intersect
   (solution is the point satisfying all equations simultaneously)
2. Column Capture: (col by col) - each col of the matrix is treated as a vector - linear combination of A cols is equal to b
   (goal is to find the right cobination, i,e scaling factors of the col vectos so they can add up to b)

## Key concepts and definitions

1. **Linear combination:** c1v1 + c2v2 + c3v3 + ... + CnVn - multiply each vector by a scalar and sum up the results
2. **Span of a set of vectors:** every set of vectors that can be produced by taking linear combination of those vectors (i.e. the spaces we can reach)

## When does Ax = b have no solution?

when vector b does not lie in the column space (image) of the matrix A - when b cannot be written as a linear combination of the column vectors of A

## confusing part

-- understanding row capture
