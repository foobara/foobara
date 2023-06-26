<!-- TOC -->
* [Creating a schema](#creating-a-schema)
  * [Options for .new](#options-for-new)
    * [```type:```](#type)
      * [Primitive types](#primitive-types)
        * [```:integer```](#integer)
        * [```:float```](#float)
        * [```:biginteger```](#biginteger)
        * [```:bigdecimal```](#bigdecimal)
        * [```:string```](#string)
        * [```:rawdata```](#rawdata)
        * [```:date```](#date)
        * [```:datetime```](#datetime)
      * [Collection types](#collection-types)
        * [```:hash```](#hash)
        * [```:array```](#array)
      * [Special types](#special-types)
        * [```:duck```](#duck)
        * [```:builtin```](#builtin)
        * [```:attributes```](#attributes)
        * [```:id```](#id)
        * [```:record```](#record)
        * [```:entity```](#entity)
* [TODO](#todo)
<!-- TOC -->

# Creating a schema

Schemas are defined by passing a nested structure of the types and validation options to the Schema constructor.

```ruby
schema = Schema.new(type: :integer, default: 0)
```

In this simple example we are expressing that we expect an integer, or something that can be cast to an integer.

Because we set the default option with ```default: 0```, we expect an error if we validate `nil` against this schema.

```ruby
schema.process(5)
# => 5

schema.process()
# => 0
```

## Options for .new

### ```type:```

Specifies the type of this 

#### Primitive types

##### ```:integer```
##### ```:float```
##### ```:biginteger```
##### ```:bigdecimal```
##### ```:string```
##### ```:rawdata```
##### ```:date```
##### ```:datetime```

#### Collection types

##### ```:hash```

A Ruby Hash or something that can be cast to one.

For this type, there are additional options: ```key_schema:``` and ```value_schema:``` which follow the same rules.
Both default to ```{ type: :duck }```

##### ```:array```

A Ruby Array or something that can be cast to one.

For this type, there is an additional option: ```element_schema:``` which defaults to ```{ type: :duck }```

#### Special types

##### ```:duck```

Anything goes. Anything is considered valid for this type.

##### ```:builtin```

Must start with a capital letter and refer to a Class that will be in memory by the time this schema is applied to any actual data.

##### ```:attributes```

This is the most important type as it defines model schemas and command input schemas, and sometimes result schemas.

It is like a map but the key_schema is always of type `:symbol` and the value_schema doesn't default to `:duck`.

##### ```:id```

A value that can be used to load a record from a store. Often this is the value of a primary key in an SQL table when using an ORM.

##### ```:record```

An instance of an entity.

##### ```:entity```

Takes either a record or an id. Convenient for when you have some code-paths that already have the indicated
record and would like to avoid a redundant query.

# TODO

* Add documentation for sugars
* Add documentation for grammar
* Seems like this could be broken out into its own gem.
