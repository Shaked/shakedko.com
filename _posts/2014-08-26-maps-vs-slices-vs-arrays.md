---
layout: post
title: "Maps VS Slices VS Arrays"
date: 2014-08-26 00:00:00 -0500
categories: Go
tags: [Golang, gomobiledetect, packages]
author: Shaked Klein Orbach
redirect_from:
  - /maps-vs-slices-vs-arrays
  - /maps-vs-slices-vs-arrays.html
---

## Description

While working on the [Gomobiledetect package](https://github.com/Shaked/gomobiledetect "Gomobiledetect - Github") I have been facing some interesting performance issues such as [caching the compiled regex rules](https://groups.google.com/d/msg/golang-nuts/rB8CcqlXY-U/MORl3u6bkSgJ "Golang-nuts - Compiled Regex Caching Idea") and changing the maps to slices(expandable arrays on runtime) or arrays(fixed size) - depends on the situation.

Today I want to talk about the performance improvement I have faced while working on gomobiledetect.

### Simple Example

Before getting into the package's improvements, lets start with a basic example. I have written a small package which uses 3 different structures:

1. Map
2. Slice - Expandable
3. Slice - Fixed Size
4. Array

The benchmarks include:

1. Defer-Recover-Panic
2. Inserting values
3. Searching values
4. Deleting values

##### Results

```
$ map-vs-slice-vs-array $ go test -bench=.
testing: warning: no tests to run
PASS
BenchmarkDeferRecoverPanicMap       10000        215850 ns/op
BenchmarkDeferRecoverPanicSliceExpandable     100000         28785 ns/op
BenchmarkDeferRecoverPanicSliceFixedSize      200000         14172 ns/op
BenchmarkDeferRecoverPanicArray   200000          8329 ns/op
BenchmarkRunMap    10000        215273 ns/op
BenchmarkRunSliceExpandable   100000         27926 ns/op
BenchmarkRunSliceFixedSize    200000         13603 ns/op
BenchmarkRunArray     500000          5959 ns/op
BenchmarkSearchMap     10000        254402 ns/op
BenchmarkSearchSliceExpandable    100000         28852 ns/op
BenchmarkSearchSliceFixedSize     100000         14869 ns/op
BenchmarkSearchArray      200000          8632 ns/op
BenchmarkDeleteMap     10000        260431 ns/op
BenchmarkDeleteSlicePreservingOrder   500000          7045 ns/op
BenchmarkDeleteSliceWithoutPreservingOrder    500000          5876 ns/op
ok      Shaked/map-vs-slice-vs-array 39.698s
```

##### Actual Code

Full code available at [GitHub Gist](https://gist.github.com/Shaked/e46aa01741edf51dda6a)

##### Benchmark Code

Full code available at [GitHub Gist](https://gist.github.com/Shaked/e46aa01741edf51dda6a)

### Complex Example

Basically the difference between the simple example and this example is only the types that I have used, e.g: `int` vs `io.Reader`

##### Results

```
complex $ go test -bench=.
testing: warning: no tests to run
PASS
BenchmarkDeferRecoverPanicMap       5000        302902 ns/op
BenchmarkDeferRecoverPanicSliceExpandable      10000        114866 ns/op
BenchmarkDeferRecoverPanicSliceFixedSize       20000         91200 ns/op
BenchmarkDeferRecoverPanicArray    20000         90487 ns/op
BenchmarkRunMap    10000        297342 ns/op
BenchmarkRunSliceExpandable    10000        110090 ns/op
BenchmarkRunSliceFixedSize     20000         89525 ns/op
BenchmarkRunArray      20000         96333 ns/op
BenchmarkSearchMap      5000        335909 ns/op
BenchmarkSearchSliceExpandable     10000        113070 ns/op
BenchmarkSearchSliceFixedSize      20000         91075 ns/op
BenchmarkSearchArray       20000         89402 ns/op
BenchmarkDeleteMap      5000        348145 ns/op
BenchmarkDeleteSlicePreservingOrder   200000          7810 ns/op
BenchmarkDeleteSliceWithoutPreservingOrder    500000          7163 ns/op
ok      Shaked/map-vs-slice-vs-array/complex 33.417s
```

##### Actual Code

Full code available at [GitHub Gist](https://gist.github.com/Shaked/33dea3c6fb906a8b361e)

##### Benchmark Code

Full code available at [GitHub Gist](https://gist.github.com/Shaked/33dea3c6fb906a8b361e)

### Mobiledetect Example

I have made a lot of changes in the package which can be seen [here](https://github.com/Shaked/gomobiledetect/commit/b916d89319f06b43fcd78cf856a26c3d90c6d946 "Mobiledetect Changes from Maps to Slices\Arrays")

The results were **amazing**.
The old version including maps showed:

```
BenchmarkIsMobile       2000       1001884 ns/op
ok      github.com/Shaked/gomobiledetect    7.091s
```

While the current version showed:

```
BenchmarkIsMobile     100000         19278 ns/op
ok      github.com/Shaked/gomobiledetect    7.448s
```

At the moment I have decided to continue supporting backwards which means that I am still using a map that maps between the string and the integer value of the keys.

### Open question

I think that its clear that one should aim to use proper arrays or slices but then as we know that maps **are needed** a good question would be: when?

