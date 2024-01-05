entity inputs...

one option...

have types like...

```
class SomeCommand
  inputs referring_user: User::Reference
end  
```

or

```
class SomeCommand
  inputs referring_user: User.reference
end  
```

Other option:

make the command declare what it mutates...

```ruby

class SomeCommand
  inputs referring_user: User

  mutates :referring_user, :fan_count
end
```

Pros/cons:

* input types
    * pros
        * can better set expectations with the outside world
        * could be helpful in various contexts and leveraged by
          transformers
        * can give a bit better control/expressiveness around primary key types
    * cons
        * A lot more stuff to learn about entities in inputs
* mutates helper
    * pros
        * more fine grained control over what will be changed
    * cons
        * would need to mutate inputs_type in reaction
          to what can be mutated

Maybe do both??

Should we give errors if mutating something not declared as being mutated?

Maybe have a readonly concept?

Concepts:

* backend
    * thunk
        * may or may not be loaded, is lazy loaded
    * atom
        * only seems to come up in serializers
    * aggregate
        * comes up in serializers and command connector transaction stuff (pre-commit transformers)
* frontend (all readonly)
    * UnloadedUser
        * This is like a "UserReference" and that might be a better name.
    * LoadedUser
        * Is loaded to at least the atom level
    * UserAtom
        * all attributes set but all association attributes are set to
          unloaded versions of those entities
    * UserAggregate
        * all attruibutes set and all association attributes are set to
          aggregated versions of those entities
    * User(Ambiguous)
        * May or may not be loaded. Might be better expressed as User | UserReference
          and changing User to be what LoadedUser currently is

TODO:

1. Make an entity_reference type and make an input transformer that changes all entities in the inputs to entity
   references
2. Exclude entity errors from possible errors unless the path is in the mutates paths.

which to do first?

1 seems bad... it's not really about whether its a reference or not.
It's if it's mutatable or not... how do we express that??

Maybe an entity extension? ugg.

Real TODO:

1. Make a mutable: supported processor for entity types.
    1. Defaults to false, ie, not mutable
    2. Can be set to true if whole thing is mutable, or, to an array of symbols of mutable attributes (possibly should
       be an array of paths since an attribute could be attributes itself)
    3. Do we need a new type? An entity extension or reference? This is confusion but not sure.
2. Create a supported processor for the loadedness of an entity.
    1. If it's loaded, then no not-found error is possible.
    2. default is may or may not be loaded (ambiguous)
    3. This is less pressing so will probably procrastinate on this.

How do we communicate that a record is pre-existing and valid??




