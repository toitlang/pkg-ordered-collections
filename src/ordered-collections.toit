// Copyright (C) 2024 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

MAX-PRINT-STRING_ ::= 4000

abstract
mixin ToListMixin_:
  abstract size -> int
  abstract do [block] -> none

  /**
  Returns a list of keys, without removing them from the set.
  */
  to-list -> List:
    result := List size
    index := 0
    do: | key |
      result[index++] = key
    return result

abstract
class NodeTree_:
  abstract empty-string_ -> string

  root_ /TreeNode? := null
  size_ /int := 0

  size -> int:
    return size_

  is-empty -> bool:
    return root_ == null

  do [block] -> none:
    if root_:
      do_ root_ block

  do --reversed/bool [block] -> none:
    if reversed != true: throw "Argument Error"
    if root_:
      do-reversed_ root_ block

  /**
  Returns the smallest element of this collection.
  The collection must not be empty.
  */
  first -> any:
    do: return it
    throw "empty"

  /**
  Returns the largest element of this collection.
  The collection must not be empty.
  */
  last -> any:
    do --reversed: return it
    throw "empty"

  /**
  Clears this collection, setting the size to 0.
  */
  clear -> none:
    root_ = null
    size_ = 0

  static LEFT_ ::= 0
  static CENTER_ ::= 1
  static RIGHT_ ::= 2
  static UP_ ::= 3

  do_ node/TreeNode [block] -> none:
    // Avoids recursion because it can go too deep on the splay tree.
    // Also avoids a collection based stack, since we have parent pointers, and
    //   can avoid unnecessary allocation.
    direction := LEFT_
    while true:
      if direction == LEFT_:
        if node.left_:
          node = node.left_
        else:
          direction = CENTER_
      else if direction == CENTER_:
        block.call node
        direction = RIGHT_
      else if direction == RIGHT_:
        if node.right_:
          node = node.right_
          direction = LEFT_
        else:
          direction = UP_
      else if direction == UP_:
        parent := node.parent_
        if not parent: return
        if identical node parent.left_:
          direction = CENTER_
        else:
          direction = UP_
        node = parent

  do-reversed_ node/TreeNode? [block] -> none:
    // Avoids recursion because it can go too deep on the splay tree.
    // Also avoids a collection based stack, since we have parent pointers, and
    //   can avoid unnecessary allocation.
    direction := RIGHT_
    while true:
      if direction == RIGHT_:
        if node.right_:
          node = node.right_
        else:
          direction = CENTER_
      else if direction == CENTER_:
        block.call node
        direction = LEFT_
      else if direction == LEFT_:
        if node.left_:
          node = node.left_
          direction = RIGHT_
        else:
          direction = UP_
      else if direction == UP_:
        parent := node.parent_
        if not parent: return
        if identical node parent.right_:
          direction = CENTER_
        else:
          direction = UP_
        node = parent

  /**
  Returns either a node that compares equal or a node that is the closest
    parent to a new, correctly placed node.  The block is passed a node and
    should return a positive integer if the new node should be placed to the
    left, 0 if there is an exact match, and a negative integer if the new
    node should be placed to the right.
  If the collection is empty, returns null.
  */
  find_ [compare] -> TreeNode?:
    node/TreeNode? := root_ as any
    while node:
      if (compare.call node) > 0:
        if node.left_ == null:
          return node
        node = node.left_
      else if (compare.call node) < 0:
        if node.right_ == null:
          return node
        node = node.right_
      else:
        return node
    return null

  /**
  Only works if there are no elements that compare equal in a given collection.
  Can be used for test purposes in collections that admit duplicates,
    if you are sure there are no duplicates in the concrete collection.
  Iterates both collections in order, comparing each element, without using
    intermediate storage.
  */
  test-equals_ other/NodeTree_ -> bool:
    if other is not NodeTree_: return false
    if other.size != size: return false
    if size == 0: return true
    // Avoids recursion because it can go too deep on the splay tree.
    // Also avoids doing a log n lookup for each element, which would make
    //   the operation O(log n) instead of linear.
    // Also avoids a collection based stack, since we have parent pointers.
    node1 := root_
    node2 := other.root_
    direction1 := LEFT_
    direction2 := LEFT_
    while true:
      while direction1 != CENTER_:
        if direction1 == LEFT_:
          if node1.left_:
            node1 = node1.left_
          else:
            direction1 = CENTER_
        else if direction1 == RIGHT_:
          if node1.right_:
            node1 = node1.right_
            direction1 = LEFT_
          else:
            direction1 = UP_
        else if direction1 == UP_:
          parent := node1.parent_
          if parent == null: return true
          if identical node1 parent.left_:
            direction1 = CENTER_
          else:
            direction1 = UP_
          node1 = parent
      while direction2 != CENTER_:
        if direction2 == LEFT_:
          if node2.left_:
            node2 = node2.left_
          else:
            direction2 = CENTER_
        else if direction2 == RIGHT_:
          if node2.right_:
            node2 = node2.right_
            direction2 = LEFT_
          else:
            direction2 = UP_
        else if direction2 == UP_:
          parent := node2.parent_
          assert: parent != null
          if identical node2 parent.left_:
            direction2 = CENTER_
          else:
            direction2 = UP_
          node2 = parent
      if (node1.compare-to node2) != 0: return false
      direction1 = RIGHT_
      direction2 = RIGHT_

  /**
  A debugging method that prints a representation of the tree.
  */
  abstract dump -> none

  abstract remove element/TreeNode -> none

  /**
  Whether this instance contains a key equal to the given $node.
  Equality is determined by identity.
  */
  contains node/TreeNode -> bool:
    find_: | other |
      comparison := other.compare-to node
      if comparison == 0: return true
      comparison
    return false

  /**
  Whether this instance contains all elements of $collection.
  Equality is determined by the concrete class's contains method.
  */
  contains-all collection/Collection -> bool:
    collection.do: if not contains it: return false
    return true

  /**
  For debugging purposes, emits a textual representation of the tree,
    using Unicode line drawing characters.
  */
  dump_ node/TreeNode left-indent/string self-indent/string right-indent/string [block] -> none:
    if node.left_:
      dump_ node.left_ (left-indent + "  ") (left-indent + "╭─") (left-indent + "│ "):
        if not identical node.left_.parent_ node:
          throw "node.left_.parent is not node (node=$node, node.left_=$node.left_, node.left_.parent_=$node.left_.parent_)"
      block.call node node.left_
    print self-indent + node.stringify
    if node.right_:
      dump_ node.right_ (right-indent + "│ ") (right-indent + "╰─") (right-indent + "  "):
        if not identical node.right_.parent_ node:
          throw "node.right_.parent is not node (node=$node, node.right_=$node.right_, node.right_.parent_=$node.right_.parent_)"
      block.call node node.right_

  overwrite-child_ from/TreeNode to/TreeNode? -> none:
    overwrite-child_ from to --parent=from.parent_
    from.parent_ = null

  overwrite-child_ from/TreeNode to/TreeNode? --parent -> none:
    if parent:
      if identical parent.left_ from:
        parent.left_ = to
      else:
        assert: identical parent.right_ from
        parent.right_ = to
    else:
      root_ = to
    if to:
      to.parent_ = parent

  stringify -> string:
    if size == 0: return empty-string_
    key-value-strings := []
    size := 0
    do_ root_ : | node |
      key-value-string := node.stringify
      size += key-value-string.size + 2
      if size > MAX-PRINT-STRING_:
        return "{$(key-value-strings.join ", ")..."
      key-value-strings.add key-value-string
    return "{$(key-value-strings.join ", ")}"

/// Used to implement $SplaySet.
class SetSplayNode_ extends SplayNode:
  key_ /Comparable := ?

  constructor .key_:

  compare-to other/SetSplayNode_ -> int:
    return key_.compare-to other.key_

  compare-to other/SetSplayNode_ [--if-equal] -> int:
    return key_.compare-to other.key_ --if-equal=: | self other |
      return if-equal.call self.key_ other.value

  stringify -> string:
    return key_.stringify

/// Used to implement $SplayMap.
class MapSplayNode_ extends SetSplayNode_:
  value_ := ?

  constructor key .value_:
    super key

  stringify -> string:
    return "$key_: $value_"

/// Used to implement $RedBlackSet.
class SetRedBlackNode_ extends RedBlackNode:
  key_ /Comparable := ?

  constructor .key_:

  compare-to other/SetRedBlackNode_ -> int:
    return key_.compare-to other.key_

  compare-to other/SetRedBlackNode_ [--if-equal] -> int:
    return key_.compare-to other.key_ --if-equal=: | self other |
      return if-equal.call self.key_ other.value

  stringify -> string:
    return key_.stringify

/// Used to implement $RedBlackMap.
class MapRedBlackNode_ extends SetRedBlackNode_:
  value_ := ?

  constructor key .value_:
    super key

  stringify -> string:
    return "$key_: $value_"

abstract
mixin SetMixin_:
  abstract size -> int

  abstract do [block] -> none

  abstract find_ [compare] -> TreeNode?

  /**
  Returns an element that is equal to the $key, according to the
    compare-to method of the elements in the set.
  Returns null if no element in the set is equal to the key.
  The $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  get key -> any:
    return get key --if-absent=(: null)

  /**
  Returns an element that is equal to the $key, according to the
    compare-to method of the elements in the set.
  Returns the result of calling $if-absent with the given key if no element
    in the set is equal to the key.
  The $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  get key [--if-absent] -> any:
    find_: | node |
      comparison/int := node.key_.compare-to key
      if comparison == 0: return node.key_
      comparison  // Block result.
    return if-absent.call key

/**
A set of keys.
The objects used as keys must be $Comparable and immutable in the sense
  that they do not change their comparison value while they are in the set.
Equality is determined by the compare-to method from $Comparable.
A hash code is not needed for the keys.  Duplicate keys will not be added.
Iteration is in increasing order of the keys.
Since this collection bases on a splay tree it is not guaranteed to be
  efficient for all access patterns, but is believed to be efficient in
  practice.
*/
class SplaySet extends SplayNodeTree_ with ToListMixin_ CollectionMixin SetMixin_ SetMapMixin_ implements Collection:
  operator == other/SplaySet -> bool:
    return test-equals_ other

  /**
  Adds the given $key to this instance.
  If an equal key is already in this instance, it is overwritten by the new one.
  */
  add key/Comparable -> none:
    add_
        (: SetSplayNode_ key)
        (: it.key_.compare-to key)
        (: | node/SetSplayNode_ | node.key_ = key)

  do [block] -> none:
    super: block.call it.key_

  do --reversed/bool [block] -> none:
    if not reversed: throw "Argument Error"
    super --reversed: block.call it.key_

  map [block] -> SplaySet:
    result := SplaySet
    do: result.add (block.call it)
    return result

  copy -> SplaySet:
    return map: it

/**
Common methods that sets and maps have.
*/
abstract
mixin SetMapMixin_:
  abstract find_ [compare] -> TreeNode?
  abstract remove_ element/SplayNode -> none

  /**
  Removes a key equal to the given $key from this instance.
  Equality is determined by the compare-to method from $Comparable.
  The key does not need to be present.
  */
  remove key -> none:
    remove key --if-absent=(: null)

  /**
  Removes a key equal to the given $key from this instance.
  Equality is determined by the compare-to method from $Comparable.
  If the key is absent, calls $if-absent with the given key.
  */
  remove key [--if-absent] -> none:
    nearest/any := find_: | node |
      node.key_.compare-to key
    if nearest:
      if (nearest.key_.compare-to key) == 0:
        remove_ nearest
      else:
        if-absent.call key

  /**
  Removes all elements of $collection from this instance.
  The elements in the collection can be lightweight objects that can be
    passed as a parameter to the compare-to method of keys in this set.
  */
  remove-all collection/Collection -> none:
    collection.do: remove it --if-absent=: null

  contains key -> bool:
    find_: | node |
      comparison/int := node.key_.compare-to key
      if comparison == 0: return true
      comparison  // Block result.
    return false

  empty-string_ -> string: return "{}"

/**
A map of key-value pairs.
The objects used as keys must be $Comparable and immutable in the sense
  that they do not change their comparison value while they are in the set.
Equality of keys is determined by the compare-to method from $Comparable.
A hash code is not needed for the keys.  Duplicate keys will not be added.
Iteration is in increasing order of the keys.
Since this collection bases on a splay tree it is not guaranteed to be
  efficient for all access patterns, but is believed to be efficient in
  practice.
*/
class SplayMap extends SplayNodeTree_ with SetMapMixin_ MapMixin:
  /**
  Returns the value that corresponds to the given key.
  The $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  operator [] key:
    return get key --if-absent=: throw "NOT_FOUND"

  get key:
    return get key --if-absent=(: return null) --if-present=: it

  get key [--if-absent] -> any:
    return get key --if-absent=if-absent --if-present=: it

  get key [--if-present] -> any:
    return get key --if-absent=(: return null) --if-present=if-present

  get key [--if-absent] [--if-present] -> any:
    find_: | other/MapSplayNode_ |
      comparison/int := other.key_.compare-to key
      if comparison == 0:
        return if-present.call other.value_
      comparison  // Block return value.
    return if-absent.call key

  get key [--init]:
    new-node := add_ 
        (: MapSplayNode_ key init.call)
        (: it.key_.compare-to key)
        (: | node/MapSplayNode_ | return node.value_)
    return (new-node as MapSplayNode_).value_

  /**
  Updates or adds the value that corresponds to the given key.
  If you are updating a key-value pair that is already in the map,
    the given $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  operator []= key value -> none:
    add_
        (: MapSplayNode_ key value)
        (: it.key_.compare-to key)
        (: | nearest/MapSplayNode_ | nearest.value_ = value)

  do [block] -> none:
    if root_:
      do_ root_: block.call it.key_ it.value_

  do --reversed/bool [block] -> none:
    if reversed != true: throw "Argument Error"
    if root_:
      do-reversed_ root_: block.call it.key_ it.value_

  map [block] -> SplayMap:
    result := SplayMap
    do: | key value |
      result[key] = block.call key value
    return result

  copy -> SplayMap:
    return map: | _ value | value

  empty-string_ -> string: return "{:}"

/**
A set of keys.
The objects used as keys must be $Comparable and immutable in the sense
  that they do not change their comparison value while they are in the set.
Equality is determined by the compare-to method from $Comparable.
A hash code is not needed for the keys.  Duplicate keys will not be added.
Iteration is in increasing order of the keys.
Since this collection is based on a red-black tree it offers O(log n)
  time for insertion and removal.  Checking for containment and getting
  the largest and smallest elements are also O(log n) time operations.
*/
class RedBlackSet extends RedBlackNodeTree_ with ToListMixin_ CollectionMixin SetMixin_ SetMapMixin_ implements Collection:
  operator == other/RedBlackSet -> bool:
    return test-equals_ other

  /**
  Adds the given $key to this instance.
  If an equal key is already in this instance, it is overwritten by the new one.
  */
  add key/Comparable -> none:
    add_
        (: SetRedBlackNode_ key)
        (: it.key_.compare-to key)
        (: | node/SetRedBlackNode_ | node.key_ = key)

  do [block] -> none:
    super: block.call it.key_

  do --reversed/bool [block] -> none:
    if not reversed: throw "Argument Error"
    super --reversed: block.call it.key_

  map [block] -> RedBlackSet:
    result := RedBlackSet
    do: result.add (block.call it)
    return result

  copy -> RedBlackSet:
    return map: it

/**
A map of key-value pairs.
The objects used as keys must be $Comparable and immutable in the sense
  that they do not change their comparison value while they are in the set.
Equality of keys is determined by the compare-to method from $Comparable.
A hash code is not needed for the keys.  Duplicate keys will not be added.
Iteration is in increasing order of the keys.
Since this collection is based on a red-black tree it offers O(log n)
  time for insertion and removal.  Checking for containment and getting
  the largest and smallest keys are also O(log n) time operations.
*/
class RedBlackMap extends RedBlackNodeTree_ with SetMapMixin_ MapMixin:
  /**
  Returns the value that corresponds to the given key.
  The $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  operator [] key:
    return get key --if-absent=: throw "NOT_FOUND"

  get key:
    return get key --if-absent=(: return null) --if-present=: it

  get key [--if-absent] -> any:
    return get key --if-absent=if-absent --if-present=: it

  get key [--if-present] -> any:
    return get key --if-absent=(: return null) --if-present=if-present

  get key [--if-absent] [--if-present] -> any:
    find_: | other/MapRedBlackNode_ |
      comparison/int := other.key_.compare-to key
      if comparison == 0:
        return if-present.call other.value_
      comparison  // Block return value.
    return if-absent.call key

  get key [--init]:
    new-node := add_ 
        (: MapRedBlackNode_ key init.call)
        (: it.key_.compare-to key)
        (: | node/MapRedBlackNode_ | return node.value_)
    return (new-node as MapRedBlackNode_).value_

  /**
  Updates or adds the value that corresponds to the given key.
  If you are updating a key-value pair that is already in the map,
    the given $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  operator []= key value -> none:
    add_
        (: MapRedBlackNode_ key value)
        (: it.key_.compare-to key)
        (: | node/MapRedBlackNode_ | node.value_ = value)

  do [block] -> none:
    if root_:
      do_ root_: block.call it.key_ it.value_

  do --reversed/bool [block] -> none:
    if reversed != true: throw "Argument Error"
    if root_:
      do-reversed_ root_: block.call it.key_ it.value_

  map [block] -> RedBlackMap:
    result := RedBlackMap
    do: | key value |
      result[key] = block.call key value
    return result

  copy -> RedBlackMap:
    return map: | _ value | value

  empty-string_ -> string: return "{:}"

/**
A splay tree which self-adjusts to avoid imbalance on average.
Iteration is in order of the elements according to the compare-to method.
This tree can store elements that are subtypes $SplayNode.
See $SplaySet for a version that can store any element.
Implements $Collection.
The nodes should implement $Comparable.  The same node cannot be
  added twice or added to two different trees, but a tree can contain
  two different nodes that are equal according to compare-to method.
To remove a node from the tree, use a reference to the node.
Since this collection bases on a splay tree it is not guaranteed to be
  efficient for all access patterns, but is believed to be efficient in
  practice.
*/
class SplayNodeTree extends SplayNodeTree_ with ToListMixin_ CollectionMixin implements Collection:
  /**
  Adds an element to this tree.
  The element must not already be in a tree.
  */
  add element/SplayNode -> none:
    assert: element.parent_ == null
    assert: element.left_ == null
    assert: element.right_ == null
    size_++
    if root_ == null:
      root_ = element
      return
    insert_ element (root_ as SplayNode)
    splay_ element

  empty-string_ -> string: return "[]"

abstract
class SplayNodeTree_ extends NodeTree_:
  /**
  Removes the given element from this tree.
  Equality is determined by object identity ($identical).
  The given element must be in this tree.
  */
  remove element/SplayNode -> none:
    remove_ element

  remove_ element/SplayNode -> none:
    parent := element.parent_
    assert: parent != null or (identical root_ element)
    assert:
      e := element
      while not identical e root_:
        e = e.parent_
      identical e root_  // Assert that the item being removed is in this tree.
    size_--
    if element.left_ == null:
      if element.right_ == null:
        // No children.
        overwrite-child_ element null
      else:
        // Only right child.
        overwrite-child_ element element.right_
    else:
      if element.right_ == null:
        // Only left child.
        overwrite-child_ element element.left_
      else:
        // Both children exist.  Move up the left child to be the new
        // parent.
        replacement := element.left_
        old-right := replacement.right_
        replacement.right_ = element.right_
        element.right_.parent_ = replacement
        overwrite-child_ element replacement
        if old-right:
          insert_ old-right replacement
          splay_ replacement
          return
    element.right_ = null
    element.left_ = null

    if parent:
      splay_ parent

    assert: element.parent_ == null
    assert: element.left_ == null
    assert: element.right_ == null

  add_ [create] [compare] [overwrite] -> SetSplayNode_:
    nearest/any := find_ compare
    if nearest:
      comparison := compare.call nearest
      if comparison == 0:
        // Equal.  Overwrite.
        overwrite.call nearest
        splay_ nearest
        return nearest
      node := create.call
      node.parent_ = nearest
      if comparison > 0:
        nearest.left_ = node
      else:
        nearest.right_ = node
      size_++
      splay_ node
      return node
    else:
      root_ = create.call
      size_ = 1
      return root_ as SetSplayNode_

  insert_ element/SplayNode node/SplayNode -> none:
    while true:
      if (element.compare-to node) < 0:
        if node.left_ == null:
          element.parent_ = node
          node.left_ = element
          return
        node = node.left_
      else:
        if node.right_ == null:
          element.parent_ = node
          node.right_ = element
          return
        node = node.right_

  splay_ node/SplayNode -> none:
    while node.parent_:
      parent := node.parent_
      grandparent := parent.parent_
      if grandparent == null:
        rotate_ node
      else:
        if ((identical node parent.left_) and (identical parent grandparent.left_)) or
           ((identical node parent.right_) and (identical parent grandparent.right_)):
          rotate_ parent
          rotate_ node
        else:
          rotate_ node
          rotate_ node

  rotate_ node/SplayNode -> none:
    parent := node.parent_
    if parent == null:
      return
    grandparent := parent.parent_
    if grandparent:
      if identical parent grandparent.left_:
        grandparent.left_ = node
      else:
        assert: identical parent grandparent.right_
        grandparent.right_ = node
    else:
      root_ = node
    if identical node parent.left_:
      parent.left_ = node.right_
      if node.right_:
        node.right_.parent_ = parent
      node.right_ = parent
    else:
      assert: identical node parent.right_
      parent.right_ = node.left_
      if node.left_:
        node.left_.parent_ = parent
      node.left_ = parent
    node.parent_ = grandparent
    parent.parent_ = node

  /**
  A debugging method that prints a representation of the tree.
  */
  dump --check=true -> none:
    print "***************************"
    if root_:
      if root_.parent_:
        throw "root_.parent is not null"
      dump_ root_ "" "" "": | parent child |
        if not identical child.parent_ parent:
          throw "child.parent is not parent"

/**
A red-black tree which self-adjusts to avoid imbalance.
Iteration is in increasing order of the elements according to the compare-to
  method.
This tree can store elements that are subtypes of $RedBlackNode.
See $RedBlackSet for a version that can store any element.
Implements $Collection.
The nodes should implement $Comparable.  The same node cannot be
  added twice or added to two different trees, but a tree can contain
  two different nodes that are equal according to compare-to method.
To remove a node from the tree, use a reference to the node.
Since this collection is based on a red-black tree it offers O(log n)
  time for insertion and O(1) amortized time for removal.
Getting the largest and smallest keys are also O(log n) time operations.
*/
class RedBlackNodeTree extends RedBlackNodeTree_ with ToListMixin_ CollectionMixin implements Collection:
  /**
  Adds a value to this tree.
  The value must not already be in a tree.
  */
  add value/RedBlackNode -> none:
    // The value cannot already be in a tree.
    assert: value.parent_ == null
    assert: value.left_ == null
    assert: value.right_ == null
    size_++
    if root_ == null:
      root_ = value
      value.red_ = false
      return
    value.red_ = true
    insert_ value (root_ as any)

  empty-string_ -> string: return "[]"

abstract
class RedBlackNodeTree_ extends NodeTree_:
  add_ [create] [compare] [overwrite] -> SetRedBlackNode_:
    nearest/any := find_ compare
    if nearest:
      comparison := compare.call nearest
      if comparison == 0:
        // Equal.  Overwrite.
        overwrite.call nearest
        return nearest
      node := create.call
      insert_ node nearest
      size_++
      return node
    else:
      root_ = create.call
      size_ = 1
      return (root_ as SetRedBlackNode_)

  insert_ value/RedBlackNode node/RedBlackNode -> none:
    while true:
      if (node.compare-to value) > 0:
        if node.left_ == null:
          value.parent_ = node
          node.left_ = value
          value.red_ = true
          add-fix-invariants_ value node
          return
        node = node.left_
      else:
        if node.right_ == null:
          value.parent_ = node
          node.right_ = value
          value.red_ = true
          add-fix-invariants_ value node
          return
        node = node.right_

  add-fix-invariants_ node/RedBlackNode parent/RedBlackNode? -> none:
    while not identical node root_:
      if not parent.red_:
        // I1.
        return
      grandparent := parent.parent_
      if grandparent == null:
        // I4.
        parent.red_ = false
        return
      index := (identical parent grandparent.left_) ? 0 : 1
      uncle := grandparent.get_ (1 - index)
      if is-black_ uncle:
        // I5 or I6, parent is red, uncle is black.
        sibling := index == 0 ? parent.right_ : parent.left_
        if identical node sibling:
          // I5, parent is red, uncle is black node is inner grandchild of
          // grandparent.
          rotate_ parent index
          node = parent
          parent = grandparent.get_ index
          // Fall through to I6.
        rotate_ grandparent (1 - index)
        parent.red_ = false
        grandparent.red_ = true
        return
      else:
        // I2, parent and uncle are red.
        parent.red_ = false
        uncle.red_ = false
        grandparent.red_ = true
        node = grandparent
        parent = node.parent_
    // I3.

  rotate_ parent/RedBlackNode index/int -> none:
    grandparent := parent.parent_
    sibling := parent.get_ (1 - index)
    close := sibling.get_ index  // Close nephew.
    if index == 0:
      parent.right_ = close
    else:
      parent.left_ = close
    if close: close.parent_ = parent
    if index == 0:
      sibling.left_ = parent
    else:
      sibling.right_ = parent
    parent.parent_ = sibling
    sibling.parent_ = grandparent
    if grandparent:
      if identical parent grandparent.right_:
        grandparent.right_ = sibling
      else:
        grandparent.left_ = sibling
    else:
      root_ = sibling

  /**
  Removes the given value from this tree.
  Equality is determined by object identity ($identical).
  The given value must be in this tree.
  */
  remove value/RedBlackNode -> none:
    remove_ value

  // Helper.  We can't just inline this into $remove because it calls itself
  // and a subclass overrides $remove.
  remove_ value/RedBlackNode -> none:
    parent := value.parent_
    left := value.left_
    right := value.right_
    assert: parent != null or identical root_ value
    assert:
      v := value
      while not identical v root_:
        v = v.parent_
      identical v root_
    size_--
    if left == null:
      if right == null:
        // Leaf node.
        index := (not parent or (identical value parent.left_)) ? 0 : 1
        overwrite-child_ value null
        if (not identical value root_) and not value.red_:
          // Leaf node is black - the difficult case.
          remove-fix-invariants_ value parent index
      else:
        // Only right child.
        child := right
        value.right_ = null
        overwrite-child_ value child
        child.red_ = false
    else:
      if right == null:
        // Only left child.
        child := left
        value.left_ = null
        overwrite-child_ value child
        child.red_ = false
      else:
        // Both children exist.
        // Replace with leftmost successor.
        successor := leftmost_ right
        successor-parent := successor.parent_
        successor-right := successor.right_
        // Wikipedia says we swap the payloads, then free the leftmost node
        // instead of the value node, but this version doesn't change object
        // identities, so we move the nodes in the tree.
        successor.left_ = left
        left.parent_ = successor
        value.left_ = null
        value.right_ = successor-right
        if successor-right:
          successor-right.parent_ = value
        if not identical successor-parent value:
          successor.right_ = right
          right.parent_ = successor
          overwrite-child_ value successor
          overwrite-child_ successor value --parent=successor-parent
        else:
          // Successor is the right child of value.
          overwrite-child_ value successor
          successor.right_ = value
          value.parent_ = successor
        red := successor.red_
        successor.red_ = value.red_
        value.red_ = red
        size_++  // Don't decrement twice.
        remove_ value  // After moving the nodes, call the method again.

    assert: value.parent_ == null
    assert: value.left_ == null
    assert: value.right_ == null

  remove-fix-invariants_ value/RedBlackNode parent/RedBlackNode? index/int -> none:
    if parent == null: return
    sibling := (parent.get_ (1 - index)) as RedBlackNode
    close := sibling.get_ index          // Distant nephew.
    distant := sibling.get_ (1 - index)  // Close nephew.
    while parent != null:  // return on D1
      if sibling.red_:
        // D3.
        assert: not parent.red_
        assert: is-black_ close
        assert: is-black_ distant
        rotate_ parent index
        parent.red_ = true
        sibling.red_ = false
        sibling = close
        distant = sibling.get_ (1 - index)
        close = sibling.get_ index
        // Iterate to go to D6, D5 or D4.
      else if close != null and close.red_:
        // D5.
        rotate_ sibling (1 - index)
        sibling.red_ = true
        close.red_ = false
        distant = sibling
        sibling = close
        // Iterate to go to D6.
      else if distant != null and distant.red_:
        // D6.
        rotate_ parent index
        sibling.red_ = parent.red_
        parent.red_ = false
        distant.red_ = false
        return
      else:
        // D4 and D2
        sibling.red_ = true
        if parent.red_:
          // D4.
          parent.red_ = false
          return
        // D2.  Go up the tree.
        sibling.red_ = true
        value = parent
        parent = value.parent_
        if parent:
          index = (identical value parent.left_) ? 0 : 1
          sibling = parent.get_ (1 - index)
          close = sibling.get_ index          // Distant nephew.
          distant = sibling.get_ (1 - index)  // Close nephew.
    // D1 return.

  is-black_ node/RedBlackNode? -> bool:
    return node == null or not node.red_

  leftmost_ node/RedBlackNode -> RedBlackNode:
    while node.left_:
      node = node.left_
    return node

  /**
  A debugging method that prints a representation of the tree.
  */
  dump --check=true -> none:
    print "***************************"
    if root_:
      if root_.parent_:
        throw "root_.parent is not null"
      dump_ root_ "" "" "": | parent child |
        if parent.red_ and child.red_:
          throw "red-red violation"
        if not identical child.parent_ parent:
          throw "child.parent is not parent"
      if check: check-black-depth_ (root_ as RedBlackNode) [-1] 0

  check-black-depth_ node/RedBlackNode tree-depth/List depth/int -> none:
    if not node.red_:
      depth++
    if (not node.left_ and not node.right_):
      if tree-depth[0] == -1:
        tree-depth[0] = depth
      else:
        if tree-depth[0] != depth:
          throw "black depth mismatch at $node"
    if node.left_:
      check-black-depth_ node.left_ tree-depth depth
    if node.right_:
      check-black-depth_ node.right_ tree-depth depth

abstract
class TreeNode implements Comparable:
  left_ /any := null
  right_ /any := null
  parent_ /any := null

  abstract compare-to other/TreeNode -> int
  abstract compare-to other/TreeNode [--if-equal] -> int

  get_ index/int -> TreeNode?:
    if index == 0:
      return left_
    else:
      assert: index == 1
      return right_

/**
A class that can be specialized to store nodes in a $SplayNodeTree.
*/
abstract
class SplayNode extends TreeNode:

/**
A class that can be specialized to store nodes in a $RedBlackNodeTree.
*/
abstract
class RedBlackNode extends TreeNode:
  red_ /bool := false

  get_ index/int -> RedBlackNode?:
    return (super index) as any

/**
An ordered collection for elements that are $Comparable.
Iteration is in increasing order of the elements according to the compare-to
  method.
Implements $Collection.
The nodes should implement $Comparable.  A collection can contain
  two different elements that are equal according to compare-to method.
To remove an object from the tree, use a reference to the object.
This collection is efficient if most additions and removals happen
  near the beginning or end of the collection, and if elements do not
  often test equal according to compare-to.
*/
class OrderedDeque extends Deque:
  /**
  Only for testing.  Only works if there are no elements that compare equal
    in a given collection.
  */
  test-equals_ other/OrderedDeque -> bool:
    if size != other.size: return false
    i := 0
    do: | element |
      if (element.compare-to other[i++]) != 0: return false
    return true

  /**
  Removes an element from this collection.  The element must be present in the
    collection.
  If many elements in the collection compare equal to each other using
    compare-to, that will affect the performance of this method.
  Only this (identical) object is removed, even if there are others that compare
    equal to it.
  */
  remove element/Comparable -> none:
    index := index-of
        element
        --binary-compare=: | a b | a.compare-to b
        --if-absent=: throw "NOT_FOUND"
    backwards := index
    while backwards >= 0:
      collection-element := this[backwards]
      if identical collection-element element:
        remove --at=backwards
        return
      if (collection-element.compare-to element) != 0:
        break
      backwards--
    forwards := index + 1
    while forwards < size:
      collection-element := this[forwards]
      if identical collection-element element:
        remove --at=forwards
        return
      if (collection-element.compare-to element) != 0:
        throw "NOT_FOUND"
      forwards++

  /**
  Inserts the given element into this collection.  There is no attempt to remove
    duplicates.  All elements must be ordered by their compare-to method.
  */
  add element/Comparable -> none:
    index := index-of
        element
        --binary-compare=: | a b | a.compare-to b
        --if-absent=: it
    insert --at=index element

  /**
  Returns a list of keys, without removing them from the collection.
  */
  // TODO: The Deque should have to-list, in which case we would not need this.
  to-list -> List:
    result := List size
    index := 0
    do: | key |
      result[index++] = key
    return result

/**
A set of keys.
The objects used as keys must be $Comparable and immutable in the sense
  that they do not change their comparison value while they are in the set.
Equality is determined by the compare-to method from $Comparable.
A hash code is not needed for the keys.  Duplicate keys will not be added.
Iteration is in increasing order of the keys.
This class is efficient if most additions and removals happen near the
  beginning or end of the collection.
*/
class DequeSet extends Deque:
  /**
  Returns whether the two collections are equal.  May call the compare-to
    method on every element of the collection.  The $other collection will
    be indexed into using the [] operator, so that should be efficient.
  */
  operator == other/List -> bool:
    if size != other.size: return false
    i := 0
    do: | element |
      if (element.compare-to other[i++]) != 0: return false
    return true

  /// Only for testing.
  test-equals_ other/DequeSet -> bool:
    return this == other

  /**
  Removes a key equal to the given $key from this instance.
  Equality is determined by the compare-to method from $Comparable.
  The $key does not need to be present.
  The $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  remove key -> none:
    remove key --if-absent=(: null)

  /**
  Removes a key equal to the given $key from this instance.
  Equality is determined by the compare-to method from $Comparable.
  If the key is absent, calls $if-absent with the given key.
  The $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  remove key [--if-absent] -> none:
    index := index-of
        key
        --binary-compare=: | a b | a.compare-to b
        --if-absent=:
          if-absent.call key
          return
    remove --at=index

  /**
  Removes all elements of $collection from this instance.
  The elements of the collection can be lightweight objects that can be passed
    as a parameter to the compare-to method of keys in this set.
  */
  remove-all collection/Collection -> none:
    collection.do: remove it --if-absent=: null

  /**
  Adds the given $key to this instance.
  If an equal key is already in this instance, it is overwritten by the new one.
  */
  add key/Comparable -> none:
    index := index-of
        key
        --binary-compare=: | a b | a.compare-to b
        --if-absent=: | index |
          insert --at=index key
          return
    this[index] = key

  add-all collection/Collection -> none:
    collection.do: add it

  /**
  Return whether this instance contains a key equal to the given $key.
  Equality is determined by the compare-to method from $Comparable.
  The $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  contains key -> bool:
    index-of
        key
        --binary-compare=: | a b | a.compare-to b
        --if-absent=: return false
    return true

/**
  Returns an element that is equal to the $key, according to the
    compare-to method of the elements in the set.
  Returns null if no element in the set is equal to the key.
  The $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  get key -> any:
    return get key --if-absent=(: null)

  /**
  Returns an element that is equal to the $key, according to the
    compare-to method of the elements in the set.
  Returns the result of calling $if-absent with the given key if no element
    in the set is equal to the key.
  The $key can be a lightweight object that can be passed as a
    parameter to the compare-to method of keys in this set.
  */
  get key [--if-absent] -> any:
    index/int := index-of
        key
        --binary-compare=: | a b | a.compare-to b
        --if-absent=: return if-absent.call key
    return this[index]

  /**
  Returns a list of keys, without removing them from the collection.
  */
  // TODO: The Deque should have to-list, in which case we would not need this.
  to-list -> List:
    result := List size
    index := 0
    do: | key |
      result[index++] = key
    return result

  stringify -> string:
    square := "{$super[1..]"
    // If it's not truncated, replace the trailing ] with a }.
    if square.ends-with "]": square = "$square[.. square.size - 1]}"
    return square

  map [block] -> DequeSet:
    result := DequeSet
    do: result.add (block.call it)
    return result

  copy -> DequeSet:
    return map: it
