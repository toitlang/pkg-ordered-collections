# Ordered Collections

Some extra collections for Toit that are suitable for elements with
an ordering.  They do not require elements to have a
hash-code method.

## Motivation

Regular Toit collections like `Set` and `Map` are already ordered by
insertion order.  Often this is enough, but sometimes you want to order
the collection by some other criterion. This package provides some
collections that allow you to insert and remove elements in any sequence, but
maintains them in a sorted order.

## Collections

There are currently six collections in this package.

Three of the collections (`RedBlackSet`, `SplaySet`, and `DequeSet`)
have set-like semantics, which means they don't allow duplicates.
Adding an element that would be a duplicate results in the existing
entry being overwritten.

The other three collections (`RedBlackNodeTree`, `SplayNodeTree`, and
`OrderedDeque`) allow insertion of duplicates, and require object identity to
remove elements.

Two of the collections are based on red-black trees. These have a fairly
high code size/complexity, but are efficient for large collections, because
the red-black tree offers guaranteed logarithmic time complexity.

Two of the collections are based on splay trees. These have a lower code
size/complexity, but can be less efficient for large collections. The
splay trees are self-balancing, but the balancing is probabilistic, not
guaranteed, and depends on the access patterns.

The final two collections are based on a deque.  This is a simpler data
structure, which is efficient for small collections, or collections where
additions and removals almost always happen near the start or end of the
sorted order.  Inserting or removing near the middle can cause a large
number of elements to be moved around.

### RedBlackNodeTree

This is a red-black tree that only allows you to add elements that
are subtypes of `RedBlackNode`.  To use it, you need to define a
subclass of `RedBlackNode` that implements the `compare-to` methods
from [Comparable](https://libs.toit.io/core/comparable/class-Comparable).

To remove an element from this collection you need to pass the exact element
that was added.  The user is expected to know whether an element is already in
the tree.  An element cannot be added to two different trees at once.

There is no `contains` or `find` operation, but `do` (iteration), `first` and
`last` can be used.  Duplicates are allowed in the sense that two elements can
compare equal using the `compare-to` method.  If several elements compare equal
there are no guarantees about which one is returned from `first` or `last`.

Time complexities are as follows for a single operation on a collection of size
n.
- `add`: O(log n).
- `remove`: O(1), amortized.
- `contains`: Not available.
- `first/last`: O(log n).
- Iteration over the whole collection: O(n) (and O(1) space overhead).

This is a fairly complex data structure with a large code size, but the
red-black tree is auto-balancing so it is efficient even for large collections.

### RedBlackSet

This is a collection that implements the same methods
as `Set`.  Any elements that are `Comparable` can be added to this set.
Iteration is in the order defined by the `compare-to` methods.

To remove an element from this collection you need to pass an object that
compares equal to the element that was added.  For example, the element itself
trivially fulfills this requirement, providing the `compare-to` method is
implemented correctly.

Adding an element that is equal (according to the `compare-to` method) to an
existing element will overwrite the existing element.  Thus there are no
duplicates.

Time complexities are as follows for a single operation on a collection of size
n.
- `add`: O(log n).
- `remove`: O(log n).
- `contains`: O(log n).
- `first/last`: O(log n).
- Iteration over the whole collection: O(n) (and O(1) space overhead).

This is a fairly complex data structure with a large code size, but the
red-black tree is auto-balancing so it is efficient even for large collections.

### SplayNodeTree

This is a splay tree that only allows you to add elements that
are subtypes of `SplayNode`.  To use it, you need to define a
subclass of `SplayNode` that implements the `compare-to` methods
from [Comparable](https://libs.toit.io/core/comparable/class-Comparable).

To remove an element from this collection you need to pass the exact element
that was added.  The user is expected to know whether an element is already in
the tree.  An element cannot be added to two different trees at once.

There is no `contains` or `find` operation, but `do` (iteration), `first` and
`last` can be used.  Duplicates are allowed in the sense that two elements can
compare equal using the `compare-to` method.  If several elements compare equal
there are no guarantees about which one is returned from `first` or `last`.

Typical (not worst case) time complexities are as follows for a single
operation on a collection of size n.
- `add`: O(log n).
- `remove`: O(1), amortized.
- `contains`: Not available.
- `first/last`: O(log n).
- Iteration over the whole collection: O(n) (and O(1) space overhead).

This is a medium complex data structure with a medium code size, but the
splay tree is usually auto-balancing so it can be efficient even for large
collections.

### SplaySet

This is a collection that implements the same methods
as `Set`.  Any elements that are `Comparable` can be added to this set.
Iteration is in the order defined by the `compare-to` methods.

To remove an element from this collection you need to pass an object that
compares equal to the element that was added.  For example, the element itself
trivially fulfills this requirement, providing the `compare-to` method is
implemented correctly.

Adding an element that is equal (according to the `compare-to` method) to an
existing element will overwrite the existing element.  Thus there are no
duplicates.

Typical (not worst case) time complexities are as follows for a single
operation on a collection of size n.
- `add`: O(log n).
- `remove`: O(log n).
- `contains`: O(log n).
- `first/last`: O(log n).
- Iteration over the whole collection: O(n) (and O(1) space overhead).

This is a medium complex data structure with a medium code size, but the
splay tree is usually auto-balancing so it can be efficient even for large
collections.

### OrderedDeque

This is a deque, which supports efficient insertion and deletion near the
ends of the collection. You can insert any elements that implement
`Comparable`.  The elements are stored in sorted order.

To remove an element from this collection you need to pass an object that
compares equal to the element that was added.  For example, the element itself
trivially fulfills this requirement, providing the `compare-to` method is
implemented correctly.

This collection supports the `contains` operation, although it is not a set.
Duplicates are allowed in the sense that two elements can
compare equal using the `compare-to` method.  If several elements compare equal
there are no guarantees about which one is returned from `first` or `last`.

If very few elements compare equal, then this collection allows efficient
`contains` and `remove` operations.

Given:
- a collection of size n
- the position of the element is m places from the start or end (whichever is shorter)
- there are d elements that compare equal to the element being added or removed
Time complexities are as follows for a single operation are:
- `add`: O(m), amortized.
- `remove`: O(d + m), amortized.
- `contains`: O(d + log n).
- `first/last`: O(1).
- Iteration over the whole collection: O(n) (and O(1) space overhead).

This is a simple data structure with small code size, but it is only
efficient for certain access patterns.

### DequeSet

This is a collection that implements the same methods as
as `Set`.  Any elements that are `Comparable` can be added to this set.
Iteration is in the order defined by the `compare-to` methods.

Since it is a deque, it supports efficient insertion and deletion near the
ends of the collection.

To remove an element from this collection you need to pass an object that
compares equal to the element that was added.  For example, the element itself
trivially fulfills this requirement, providing the `compare-to` method is
implemented correctly.

Adding an element that is equal (according to the `compare-to` method) to an
existing element will overwrite the existing element.  Thus there are no
duplicates.

Given:
- a collection of size n
- the position of the element is m places from the start or end (whichever is shorter)
Time complexities are as follows for a single operation are:
- `add`: O(m), amortized.
- `remove`: O(m), amortized.
- `contains`: O(log n).
- `first/last`: O(1).
- Iteration over the whole collection: O(n) (and O(1) space overhead).

This is a simple data structure with small code size, but it is only
efficient for certain access patterns.
