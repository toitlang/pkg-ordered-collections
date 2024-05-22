// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *

import ordered-collections show *

LAMBDA := :: print "timed out"

main:
  test (: SplayNodeTree): | us/int | SplayTimeout us LAMBDA
  test (: RedBlackNodeTree): | us/int | RBTimeout us LAMBDA
  test (: OrderedDeque): | us/int | FlatTimeout us LAMBDA
  test2 (: SplayNodeTree) (: | us/int | SplayTimeout us LAMBDA) (: it as SplayTimeout)
  test2 (: RedBlackNodeTree) (: | us/int | RBTimeout us LAMBDA) (: it as RBTimeout)
  test2 (: OrderedDeque) (: | us/int | FlatTimeout us LAMBDA) (: it as FlatTimeout)
  test2 --no-identity (: SplaySet) (: | us/int | us) (: it as int)
  test2 --no-identity (: RedBlackSet) (: | us/int | us) (: it as int)
  test2 (: DequeSet) (: | us/int | us) (: it as int)
  test-set: SplaySet
  test-set: RedBlackSet
  test-set: DequeSet
  test-lightweight: SplaySet
  test-lightweight: RedBlackSet
  test-lightweight: DequeSet
  bench false SplayNodeTree "splay": | us/int | SplayTimeout us LAMBDA
  bench false RedBlackNodeTree "red-black": | us/int | RBTimeout us LAMBDA
  bench true SplayNodeTree "splay": | us/int | SplayTimeout us LAMBDA
  bench true RedBlackNodeTree "red-black": | us/int | RBTimeout us LAMBDA
  bench true OrderedDeque "deque": | us/int | FlatTimeout us LAMBDA
  bench false OrderedDeque "deque": | us/int | FlatTimeout us LAMBDA

class RBTimeout extends RedBlackNode:
  us /int
  lambda /Lambda

  constructor .us .lambda:

  compare-to other/RBTimeout -> int:
    return us - other.us

  compare-to other/RBTimeout [--if-equal]-> int:
    other-us/int := other.us
    if us == other-us:
      return if-equal.call this other
    return us - other-us

  stringify -> string:
    RESET := "\x1b[0m"
    RED := "\x1b[31m"
    BLACK := "\x1b[30m"
    color := red_ ? "$RED⬤ r-$RESET" : "$(BLACK)⬤ b-$RESET"
    return "$(color)Timeout-$us"

class SplayTimeout extends SplayNode:
  us /int
  lambda /Lambda

  constructor .us .lambda:

  compare-to other/SplayTimeout -> int:
    return us - other.us

  compare-to other/SplayTimeout [--if-equal]-> int:
    other-us/int := other.us
    if us == other-us:
      return if-equal.call this other
    return us - other-us

  stringify -> string:
    return "Timeout-$us"

class FlatTimeout implements Comparable:
  us /int
  lambda /Lambda

  constructor .us .lambda:

  compare-to other/FlatTimeout -> int:
    return us - other.us

  compare-to other/FlatTimeout [--if-equal]-> int:
    other-us/int := other.us
    if us == other-us:
      return if-equal.call this other
    return us - other-us

  stringify -> string:
    return "Timeout-$us"

test [create-tree] [create-item] -> none:

  tree := create-tree.call

  elements := []

  set-random-seed "jdflkjsdlfkjsdl"

  200.repeat: | i |
    t := create-item.call (random 100)
    tree.add t
    elements.add t

  x := 0
  tree.do: | node |
    if node.us < x:
      throw "Error: $node.us < $x"
    x = node.us

  check tree

  cent := create-item.call 100

  tree.add cent

  check tree

  tree.remove cent

  check tree

  print "Tree size is $tree.size"

  elements.do: | e |
    tree.remove e
    check tree

test2 --identity/bool=true [create-tree] [create-item] [verify-item] -> none:
  print "Testing tree equality"
  tree1 := create-tree.call
  tree2 := create-tree.call
  tree3 := create-tree.call
  // Add elements in random order.
  elements1 := List 100: create-item.call it
  shuffle elements1
  // Add elements in sorted order to test for stack overflow.
  elements2 := List 100: create-item.call it
  // Add elements in reverse order to test for stack overflow.
  elements3 := List 100: create-item.call (99 - it)

  // Add elements in two different ways, so we also test add-all.
  elements1.do: tree1.add it
  tree2.add-all elements2
  elements3.do: tree3.add it

  [tree1, tree2, tree3].do: | tree |
    if not identity:
      expect (tree.contains 5)
      expect (tree.contains 10)
      expect (tree.contains-all [0, 99])
      expect (tree.contains-all [tree.first, tree.last])
      tree.remove 42
      tree.remove 84
      tree.remove 103  // Does not exist.
      tree.remove 13 --if-absent=(: throw "Should have 13")
      called := false
      tree.remove 42 --if-absent=(: called = true)
      expect called
      tree.remove-all [7, 8]
    else:
      tree.remove tree.first
      tree.remove tree.last
      tree.remove tree.last
      count := 0
      removals := []
      tree.do:
        count++
        if count == 5 or count == 90: removals.add it
      removals.do: tree.remove it
      dupes := List 5: create-item.call 1066
      tree.add-all dupes
      dupes.do: expect (tree.contains it)
      dupes.do --reversed: tree.remove it
      tree.add-all dupes
      dupes.do: tree.remove it
      dupes.do: expect-not (tree.contains it)

    expect (tree.contains tree.first)
    expect (tree.contains tree.last)
    verify-item.call tree.first
    verify-item.call tree.last
    tree.any:
      verify-item.call it
      false
    tree.every:
      verify-item.call it
      true
    prev := null
    tree.do:
      if prev != null:
        expect (prev.compare-to it) < 0
      prev = it
      verify-item.call it
    prev = null
    tree.do --reversed:
      if prev != null:
        expect (prev.compare-to it) > 0
      prev = it
      verify-item.call it
    expect-equals 95 tree.size
    expect (not tree.is-empty)

  list1 := tree1.to-list
  list2 := tree1.to-list
  list3 := tree1.to-list
  list1[1] = "no-alias"
  list2[1] = "no-alias"
  list3[1] = "no-alias"
  expect-equals (list1.stringify) (list2.stringify)
  expect-equals (list3.stringify) (list2.stringify)

  expect: tree1.test-equals_ tree2
  expect: tree1.test-equals_ tree3
  expect: tree3.test-equals_ tree2

  [tree1, tree2, tree3].do: | tree |
    tree.clear
    expect (tree.is-empty)

test-set [create-set] -> none:
  set := create-set.call

  set.add "foo"
  set.add "bar"
  set.add "baz"

  expect-equals "[bar, baz, foo]" (set.to-list.stringify)

  set.add "baz"

  expect-equals "[bar, baz, foo]" (set.to-list.stringify)

  set.remove "baz"

  expect-equals "[bar, foo]" (set.to-list.stringify)

  set.add-all ["fizz", "buzz", "fizz"]

  expect-equals "[bar, buzz, fizz, foo]" (set.to-list.stringify)

  l := set.to-list
  l[1] = "no-alias"

  expect-equals "[bar, buzz, fizz, foo]" (set.to-list.stringify)

class HashedString implements Comparable:
  str/string

  constructor .str:

  compare-to other -> int:
    if other is string:
      return str.compare-to other
    return str.compare-to other.str

  compare-to other [--if-equal] -> int:
    result/int := compare-to other
    if result != 0: return result
    return if-equal.call this other

  stringify -> string:
    return "'$str'"

/**
Test that we can use lightweight objects for contains and remove if the
  the compare-to method of the elements in the set is able to take the
  lightweight objects as arguments.
*/
test-lightweight [create]:
  set := create.call

  set.add
      HashedString "foo"

  expect (set.contains "foo")
  expect-not (set.contains "bar")

  set.add
      HashedString "bar"

  expect (set.contains "bar")
  expect-equals "['bar', 'foo']" (set.to-list.stringify)

  set.do: | element/HashedString | null

  set.remove "bar"
  expect-equals "['foo']" (set.to-list.stringify)

  ("baz/fizz/buzz/y/x".split "/").do: set.add (HashedString it)

  expect-equals "['baz', 'buzz', 'fizz', 'foo', 'x', 'y']" (set.to-list.stringify)

shuffle list/List:
  size := list.size
  indeces := List size: it
  dest := List size: it
  size.repeat: | i |
    r := random (size - i)
    dest[i] = list[indeces[r]]
    tmp := indeces[r]
    indeces[r] = indeces[size - i - 1]
    indeces[size - i - 1] = tmp
  list.replace 0 dest

check collection:
  // if collection is NodeTree: collection.dump
  i := 0
  collection.do: | node |
    i++
  if i != collection.size:
    throw "Error: $i(i) != $collection.size(collection.size)"
  i = 0
  collection.do --reversed: | node |
    i++
  if i != collection.size:
    throw "Error: $i(i) != $collection.size(collection.size)"

bench one-end/bool tree name/string [create-item] -> none:
  start := Time.monotonic-us
  list := []
  SIZE ::= 100_000
  SIZE.repeat: | i |
    r := random SIZE
    r += (i & 1) * SIZE
    t := create-item.call r
    if r >= SIZE:
      list.add t
    tree.add t

  if one-end:
    while tree.size > 0:
      tree.remove (tree.first)
  else:
    list.do: | t |
      tree.remove t
      tree.remove (tree.first)

  end := Time.monotonic-us
  print "Time $name $(one-end ? "one-end " : " ")for $SIZE elements: $((end - start) / 1000) us"
