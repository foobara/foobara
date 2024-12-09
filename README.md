<!-- TOC -->
* [What is/Why Foobara?](#what-iswhy-foobara)
  * [Commands](#commands)
  * [Discoverability](#discoverability)
  * [Implications of command-centric + discoverability](#implications-of-command-centric--discoverability)
  * [Other features for helping with Domain complexity](#other-features-for-helping-with-domain-complexity)
* [Installation](#installation)
* [Usage/Tutorial](#usagetutorial)
  * [Foobara 101](#foobara-101)
    * [Commands](#commands-1)
    * [Organizations and Domains](#organizations-and-domains)
    * [Types](#types)
    * [Models](#models)
    * [Entities](#entities)
    * [Command connectors](#command-connectors)
      * [Command-line connectors](#command-line-connectors)
      * [HTTP Command Connectors](#http-command-connectors)
      * [Async Command Connectors](#async-command-connectors)
      * [Scheduler Command Connectors](#scheduler-command-connectors)
  * [Intermediate Foobara](#intermediate-foobara)
    * [Metadata manifests for discoverability](#metadata-manifests-for-discoverability)
    * [Remote Commands](#remote-commands)
    * [Subcommands](#subcommands)
    * [Custom Errors](#custom-errors)
      * [Input Errors](#input-errors)
      * [Runtime Errors](#runtime-errors)
  * [Advanced Foobara](#advanced-foobara)
    * [Domain Mappers](#domain-mappers)
    * [Code Generators](#code-generators)
      * [Generating a new Foobara Ruby project](#generating-a-new-foobara-ruby-project)
      * [Generating a new Foobara Typescript/React project](#generating-a-new-foobara-typescriptreact-project)
      * [Geerating commands, models, entities, types, domains, organizations, etc...](#geerating-commands-models-entities-types-domains-organizations-etc)
    * [Custom types](#custom-types)
  * [Expert Foobara](#expert-foobara)
    * [Callbacks](#callbacks)
    * [Transactions in Commands](#transactions-in-commands)
    * [Transactions in tests/console](#transactions-in-testsconsole)
    * [Custom crud drivers](#custom-crud-drivers)
    * [Custom command connectors](#custom-command-connectors)
    * [Value processors](#value-processors)
    * [Custom types from scratch](#custom-types-from-scratch)
    * [Namespaces](#namespaces)
* [Additional learning materials/Documentation](#additional-learning-materialsdocumentation)
* [Contributing](#contributing)
  * [Developing locally](#developing-locally)
  * [Monorepo Structure](#monorepo-structure)
* [Licensing](#licensing)
<!-- TOC -->

# What is/Why Foobara?

Foobara is a software framework meant to help with projects that have
a complicated business domain. It accomplishes this by helping to
build projects that are command-centric and discoverable, as well as some other features.

## Commands

* Foobara commands are meant to encapsulate high-level domain operations.
* They serve as the public interface to Foobara systems/subsystems.
* They are organized into Organizations and Domains.

## Discoverability

* This means there is a formal machine-readable description of the systems/subsystems
* The implication of this is that integration code can be abstracted away.

## Implications of command-centric + discoverability

* The system better communicates the mental model of the problem and the chosen solution
* Engineers are able to spend more time writing code relevant to the domain and less time
  writing code related to specific tech-stack, software pattern, or architecture decisions.
* Engineers can spend more time operating within a specific mental model at a time instead of
  multiple mental models all at once.

## Other features for helping with Domain complexity

* Domains and Organizations
  * Domains are namespaces of Commands, types, and errors
    * Domains (and commands) have explicit, unidirectional dependencies on other domains
  * Organizations are namespaces of Domains
* Domain mappers
  * These can map a concept from one domain to another
  * This separation of concerns leads to commands that have code
    that reflects the domain they belong to as opposed to logic from many different domains
* Remote commands
  * These have the same interface as commands that live in other systems and act as a proxy to them
  * This allows rearchitecting of systems without changing interfaces and so reducing refactoring/testing required
  * These currently exist for both Ruby and Typescript
* Code generators
  * Similar to remote commands, discoverability enables other types of tooling, including code generators,
    documentation tools, etc
* An extract-repo script
  * Can be used to extract files from one Foobara project to another, preserving history
  * Making this easier can help with rearchitecting systems
* Custom crud-drivers (if needed)
  * You could hypothetically write your own custom CRUD driver that knows how
    to assemble an entity record with a clean mental model from a mismodeled legacy database

# Installation

To add foobara to an existing project, you can add `foobara` gem to your Gemfile or .gemspec as you normally would.
You can also `gem install foobara` and whatever additional foobara gems you need and use them in
scripts by requiring them.

You could also use a generator to create a new Ruby Foobara project using the `foob` gem with `gem install foob` and
then run `foob generate ruby-project --name your-org/your-new-project-name`

To create a new Typescript React project using a foobara generator, you could install the `foob` gem with `gem install foob` and then
run `foob generate typescript-react-project --project-dir your-org/your-new-project-name`

And then you can import remote commands/types/domains/errors from an existing Ruby foobara backend using:

`foob g typescript-remote-commands --manifest-url http://your.foobara.ruby.backend/manifest`

And you can also automatically generate some forms for your commands as a nice starting-point with:

`foob g typescript-react-command-form --command-name SomeOrg::SomeDomain::SomeCommand`

# Usage/Tutorial

Let's explore various Foobara concepts with some code examples!

## Foobara 101

### Commands

Foobara commands are meant to encapsulate high-level domain operations and are meant
to be the public interface to Foobara systems/subsystems.

Command's interface is heavily inspired by the great cypriss/mutations gem. Let's create a command that adds two numbers to
demonstrate Command's interface:

```ruby
#!/usr/bin/env ruby

require "foobara"

class Add < Foobara::Command
  inputs do
    operand1 :integer, :required
    operand2 :integer, :required
  end

  result :integer

  def execute
    add_operands

    sum
  end

  attr_accessor :sum

  def add_operands
    self.sum = operand1 + operand2
  end
end

require "irb"
IRB.start(__FILE__)
```

You need to `chmod u+x add.rb` to make it executable (assuming you put this in add.rb)

IRB at the end just gives us an interactive session. You could remove that and just put whatever code to test `Add`
that you want.

Note: for brevity, from now on we will leave the shebang and irb calls out of the examples.

Some things to note about recommended conventions:
* It is recommended that your #execute method be self documenting and only call helper methods
  preferably passing no arguments.
* We use runtime context via `attr_accessor :sum` to store the computed sum.

Let's play with it!

We can run our Add command several ways. First, let's create an instance of it and call the #run method:

```irb
$ ./add.rb
> command = Add.new(operand1: 2, operand2: 5)
==> #<Add:0xad20 @raw_inputs={:operand1=>2, :operand2=>5}, @error_collectio...
> outcome = command.run
==> #<Foobara::Outcome:0x00007fd9e60a3800...
> outcome.success?
==> true
> outcome.result
==> 7
```

When we run a command we get an Outcome. We can ask it if it is successful with #success? and
we can also get the result with #result and errors with #errors and other helper methods.

We can also just run it with .run without creating an instance:

```irb
> outcome = Add.run(operand1: 2, operand2: 5)
==> #<Foobara::Outcome:0x00007ffbcc641318...
> outcome.success?
==> true
> outcome.result
==> 7
```

And we can use .run! if we want just the result or an exception raised:

```irb
> Add.run!(operand1: 2, operand2: 5)
==> 7
```

Let's cause some errors!

```irb
> outcome = Add.run(operand1: "foo", operand2: 5)
==> #<Foobara::Outcome:0x00007ffbcc60aea8...
> outcome.success?
==> false
> puts outcome.errors_sentence
At operand1: Cannot cast "foo" to an integer. Expected it to be a Integer, or be a string of digits optionally with a minus sign in front
```

Here we used something that wasn't castable to an integer.

```irb
> outcome = Add.run
==> #<Foobara::Outcome:0x00007ffbcb9d97b0...
> outcome.success?
==> false
> puts outcome.errors_sentence
Missing required attribute operand1, and Missing required attribute operand2
```

Here we omitted some required attributes.

### Organizations and Domains

Domains operate as namespaces for Commands, types, and errors. Domains are namespaces, typically of Commands, types,
errors, and DomainMappers. They should group concepts related to one conceptual domain.
They can depend on other domains with unidirectional dependencies

Let's put our Add command into an IntegerMath domain:

```ruby
module IntegerMath
  foobara_domain!
end

module IntegerMath
  class Add < Foobara::Command
    inputs do
      operand1 :integer, :required
      operand2 :integer, :required
    end

    result :integer

    def execute
      add_operands

      sum
    end

    attr_accessor :sum

    def add_operands
      self.sum = operand1 + operand2
    end
  end
end
```

We create a domain by calling `.foobara_domain!` on the module we wish to make into a domain.

The typical way of putting commands and other Foobara concepts into a domain is to just define them inside that module.

We can play a bit with our new domain:

```irb
> IntegerMath.foobara_command_classes
==> [IntegerMath::Add]
> IntegerMath.foobara_lookup(:Add)
==> IntegerMath::Add
```

Organizations are namespaces of Domains. Commonly these might be the name of the team or company implementing the
domains in the organization.

Let's create an Organization and just call it FoobaraExamples and place our Domain in it:

```ruby
module FoobaraExamples
  foobara_organization!

  module IntegerMath
    foobara_domain!

    class Add < Foobara::Command
      inputs do
        operand1 :integer, :required
        operand2 :integer, :required
      end

      result :integer

      def execute
        add_operands

        sum
      end

      attr_accessor :sum

      def add_operands
        self.sum = operand1 + operand2
      end
    end
  end
end
```

And we can play with our Organization:

```irb
> FoobaraExamples.foobara_domains
==> [FoobaraExamples::IntegerMath]
```

### Types

We have so far seen one Foobara type which is `integer` but there are many others.

We used :integer to type the operands of our Add command. There are many ways to express types in Foobara
but in this case we used the attributes DSL. It has the form:

`<attribute_naem> <type_symbol> [processors] [description]`

We used a processor `:required` but there are many others and you can create your own.

We could have for example done:

```ruby
some_integer :integer, :required, one_of: [10, 20, 30], max: 100, min: 0, "An integer with some pointless validations!"
```

Not really useful but shows some existing processors that can be applied to integers.

We will avoid going deeper for now since this is Foobara 101 still so let's keep moving along.

### Models

A very important type when implementing complex domains is `model`

Let's create a simple `Capybara` model:

```ruby
class Capybara < Foobara::Model
  attributes do
    name :string, :required, "Official name"
    nickname :string, "Informal name for friends"
    age :integer, :required, "The number of times this capybara has gone around the sun"
  end
end
```

There are different ways to express types in Foobara. Here, we are using an attributes DSL.

Let's make some instances of our Capybara model

```bash
> fumiko = Capybara.new(name: "Fumiko", nickname: "foo", age: 100)
==> #<Capybara:0x00007fa27913d6e8 @attributes={:name=>"Fumiko", :nickname=>"foo", :age=>100}, @mutable=true>
> fumiko.name
==> "Fumiko"
> fumiko.age
==> 100
```

Let's use our model type in a command! Let's make a command called `IncrementAge` to
carry out a Capybara making it around the sun:

```ruby
class Capybara < Foobara::Model
  attributes do
    name :string, :required, "Official name"
    nickname :string, "Informal name for friends"
    age :integer, :required, "The number of times this capybara has gone around the sun"
  end
end

class IncrementAge < Foobara::Command
  inputs do
    capybara Capybara, :required
  end

  result Capybara

  def execute
    increment_age

    capybara
  end

  def increment_age
    capybara.age += 1
  end
end
```

Let's increment some ages!

```irb
> barbara = Capybara.new(name: "Barbara", age: 200, nickname: "bar")
==> #<Capybara:0x00007f0ac121dbf8 @attributes={:name=>"Barbara", :age=>200, :nickname=>"bar"}, @mutable=true>
> barbara.age
==> 200
> IncrementAge.run!(capybara: barbara)
==> #<Capybara:0x00007f0ac121dbf8 @attributes={:name=>"Barbara", :age=>201, :nickname=>"bar"}, @mutable=true>
> barbara.age
==> 201
```

Here we incremented Barbara's age.

Check this out though...

```ruby
> basil = IncrementAge.run!(capybara: { name: "Basil", age: 300, nickname: "baz" })
==> #<Capybara:0x00007f0ac1295f40 @attributes={:name=>"Basil", :age=>301, :nickname=>"baz"}, @mutable=true>
> basil.age
==> 301
```

Whoa, what is this?  We passed in attributes for a Capybara instead of a capybara and it gave us
back a capybara model instance. This comes in convenient in various use-cases.

### Entities

Let's upgrade our Capybara model to an entity:

```ruby
crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
Foobara::Persistence.default_crud_driver = crud_driver

class Capybara < Foobara::Entity
  attributes do
    id :integer
    name :string, :required, "Official name"
    nickname :string, "Informal name for friends"
    age :integer, :required, "The number of times this capybara has gone around the sun"
  end

  primary_key :id
end
```

Here, we added an InMemory CRUD driver and set it as the default. This lets us write/read records to/from memory.

An entity is like a model except it has a primary key and can be written/read to/from a data store using a CRUD driver.

In fact, `entity` inherits `model`. We could look at the hierarchy of Capybara with the following hack:

```ruby
def print_type_inheritance(type)
  types = Enumerator.produce(type, &:base_type).take_while { |t| !t.nil? }
  Foobara::Util.print_tree(types, to_parent: :base_type, to_name: :name)
end

capybara_type = Foobara.foobara_lookup(:Capybara)
print_type_inheritance(capybara_type)
```

Which gives us:

```irb

* def print_type_inheritance(type)
*   types = Enumerator.produce(type, &:base_type).take_while { |t| !t.nil? }
*   Foobara::Util.print_tree(types, to_parent: :base_type, to_name: :name)
> end
==> :print_type_inheritance
> capybara_type = Foobara.foobara_lookup(:Capybara)
==> #<Type:Capybara:0x88b8 {:type=>:model, :name=>"Capybara", :model_class=>"Capybara", :model_base_class=>"Foobara::Model", :attributes_declaration=>{:typ...
> print_type_inheritance(capybara_type)
> print_type_inheritance(capybara_type)
╭──────╮
│ duck │
╰──┬───╯
   │ ╭─────────────╮
   └─┤ atomic_duck │
     ╰──────┬──────╯
            │ ╭───────╮
            └─┤ model │
              ╰───┬───╯
                  │ ╭────────╮
                  └─┤ entity │
                    ╰───┬────╯
                        │ ╭──────────╮
                        └─┤ Capybara │
                          ╰──────────╯
```

While we're in here we could look at another type, like Capybara's attributes type

```irb
> print_type_inheritance(Capybara.attributes_type)
╭──────╮
│ duck │
╰──┬───╯
   │ ╭──────────╮
   └─┤ duckture │
     ╰────┬─────╯
          │ ╭───────────────────╮
          └─┤ associative_array │
            ╰─────────┬─────────╯
                      │ ╭────────────╮
                      └─┤ attributes │
                        ╰─────┬──────╯
                              │ ╭────────────────────────────────╮
                              └─┤ Anonymous attributes extension │
                                ╰────────────────────────────────╯

```

Whoa... this is supposed to be Foobara 101... let's get back to basics.

Let's make a basic CreateCapybara command:

```ruby
class CreateCapybara < Foobara::Command
  description "Just creates a capybara!"

  inputs Capybara.attributes_for_create
  result Capybara

  def execute
    create_capybara

    capybara
  end

  attr_accessor :capybara

  def create_capybara
    self.capybara = Capybara.create(inputs)
  end
end
```

And a basic FindCapybara command:

```ruby
class FindCapybara < Foobara::Command
  inputs do
    id Capybara.primary_key_type, :required
  end

  result Capybara

  def execute
    load_capybara

    capybara
  end

  attr_accessor :capybara

  def load_capybara
    self.capybara = Capybara.load(id)
  end
end
```

And now let's create some Capybara records and manipulate them:

```ruby
> fumiko = CreateCapybara.run!(name: "Fumiko", nickname: "foo", age: 100)
==> <Capybara:1>
> barbara = CreateCapybara.run!(name: "Barbara", nickname: "bar", age: 200)
==> <Capybara:2>
> basil = CreateCapybara.run!(name: "Basil", nickname: "baz", age: 300)
==> <Capybara:3>
> basil.age
==> 300
> basil = IncrementAge.run!(capybara: 3)
==> <Capybara:3>
> basil.age
==> 301
> basil = FindCapybara.run!(capybara: 3)
==> <Capybara:3>
> basil.age
==> 301
```

We were able to increment Basil's age using his primary key and we were also able to find his record.

But there is a problem... Basil's record won't be persisted across runs of our script.  That's because it is stored in
ephemeral memory. Let's instead persist it to a file. Let's install a file crud driver:

```bash
> gem install foobara-local-files-crud-driver
```

And now let's swap out the InMemory crud driver with our file crud driver:

```ruby
require "foobara/local_files_crud_driver"

crud_driver = Foobara::LocalFilesCrudDriver.new
Foobara::Persistence.default_crud_driver = crud_driver
```

Now let's create our records again and look at them on disk:

```irb
> CreateCapybara.run!(name: "Fumiko", nickname: "foo", age: 100)
==> <Capybara:1>
> CreateCapybara.run!(name: "Barbara", nickname: "bar", age: 200)
==> <Capybara:2>
> CreateCapybara.run!(name: "Basil", nickname: "baz", age: 300)
==> <Capybara:3>
> puts File.read("local_data/records.yml")
---
capybara:
  sequence: 4
  records:
    1:
      :name: Fumiko
      :nickname: foo
      :age: 100
      :id: 1
    2:
      :name: Barbara
      :nickname: bar
      :age: 200
      :id: 2
    3:
      :id: 3
      :name: Basil
      :nickname: baz
      :age: 300
```

Great! Now let's re-run our script and manipulate some data:

```irb
> basil = FindCapybara.run!(id: 3)
==> <Capybara:3>
> basil.age
==> 300
> basil = IncrementAge.run!(capybara: 3)
==> <Capybara:3>
> basil.age
==> 301
```

We were able to find Basil in a fresh run of our script!

Let's find Basil again in another fresh run:

```irb
> basil = FindCapybara.run!(id: 3)
==> <Capybara:3>
> basil.age
==> 301
```

Basil is still a respectable 301 years old!

### Command connectors

Command connectors allow us to expose our commands to the outside world using various technologies

#### Command-line connectors

Let's install a command-line connector for bash:

```bash
gem install foobara-sh-cli-connector
```

Let's use it in our script by adding the following to the bottom of our script:

```ruby
require "foobara/sh_cli_connector"


command_connector = Foobara::CommandConnectors::ShCliConnector.new

command_connector.connect(CreateCapybara)
command_connector.connect(IncrementAge)
command_connector.connect(FindCapybara)

command_connector.run(ARGV)
```

And either rename the script to capy-cafe or symlink it.

Now let's run our script again:

```irb
$ ./capy-cafe
Usage: capy-cafe [GLOBAL_OPTIONS] [ACTION] [COMMAND_OR_TYPE] [COMMAND_INPUTS]

Available commands:

  CreateCapybara   Just creates a capybara!
  IncrementAge     A trip around the sun!
  FindCapybara     Just tell us who you want to find!
```

Ohhh we get some help now and a list of command we can run. Let's learn more about FindCapybara:

```
$ ./capy-cafe help FindCapybara
Usage: capy-cafe [GLOBAL_OPTIONS] FindCapybara [COMMAND_INPUTS]

Just tell us who you want to find!

Command inputs:

 -i, --id ID                      Required
```

Oh OK, well, let's try to find Basil:

```
$ ./capy-cafe FindCapybara --id 3
id: 3,
name: "Basil",
nickname: "baz",
age: 301
```

Great! Let's see if we can increment Basil's age:

```
$ ./capy-cafe help IncrementAge
Usage: capy-cafe [GLOBAL_OPTIONS] IncrementAge [COMMAND_INPUTS]

A trip around the sun!

Command inputs:

 -c, --capybara CAPYBARA          Required

$ ./capy-cafe IncrementAge --capybara 3
id: 3,
name: "Basil",
nickname: "baz",
age: 302
$ ./capy-cafe FindCapybara --id 3
id: 3,
name: "Basil",
nickname: "baz",
age: 302
```

Yay! Now Basil is an even more respectable 302 years old!

#### HTTP Command Connectors

Let's now replace our command-line connector with an HTTP connector:

We'll choose a Rack connector for now:

```
gem install foobara-rack-connector
```

And we can wire it up by replacing the CLI connector code at the bottom of the script with this instead:

```ruby
require "foobara/rack_connector"
require "rackup/server"

command_connector = Foobara::CommandConnectors::Http::Rack.new

command_connector.connect(CreateCapybara)
command_connector.connect(IncrementAge)
command_connector.connect(FindCapybara)

Rackup::Server.start(app: command_connector)
```

NOTE: Normally we would call `run command_connector` in a config.ru file but we're hacking this up in a script
instead of in a structured project so we'll just boot the server this way.

If we run it we see:

```
Puma starting in single mode...
* Puma version: 6.5.0 ("Sky's Version")
* Ruby version: ruby 3.2.2 (2023-03-30 revision e51014f9c0) [x86_64-linux]
*  Min threads: 0
*  Max threads: 5
*  Environment: development
*          PID: 189938
* Listening on http://0.0.0.0:9292
Use Ctrl-C to stop
```

Great!  Our server has booted!

We can get help by going to http://localhost:9292/help or help with specific commands or types by going to http://localhost:9292/help/Capybara
or http://localhost:9292/help/FindCapybara etc.

Let's curl FindCapybara to find Fumiko:

```
$ curl http://localhost:9292/run/FindCapybara?id=1
{"name":"Fumiko","nickname":"foo","age":100,"id":1}
```

Yay!  We found Fumiko!

Let's celebrate her birthday:

```ruby
$ curl http://localhost:9292/run/IncrementAge?capybara=1
{"id":1,"name":"Fumiko","nickname":"foo","age":101}
$ curl http://localhost:9292/run/FindCapybara?id=1
{"name":"Fumiko","nickname":"foo","age":101,"id":1}
```

And now she is 101 as expected.

Let's try exposing our commands through the Rails router.

We'll create an a test rails app with (you can just do --api if you are too lazy to skip all the other stuff):

```ruby
gem install rails
rails rails new --api --skip-docker --skip-asset-pipeline --skip-javascript --skip-hotwire --skip-jbuilder --skip-test --skip-brakeman --skip-kamal --skip-solid rails_test_app
```

Now in `config/routes.rb` we could add:

```ruby
require "foobara/rails_command_connector"

Foobara::CommandConnectors::RailsCommandConnector.new

command_connector.connect(CreateCapybara)
command_connector.connect(IncrementAge)
command_connector.connect(FindCapybara)
```

We can start rails with:

```
$ rails s
```

And then hit our previous URLs although now the port is 3000:

```
$ curl http://localhost:3000/run/IncrementAge?capybara=1
{"id":1,"name":"Fumiko","nickname":"foo","age":102}
$ curl http://localhost:3000/run/FindCapybara?id=1
{"name":"Fumiko","nickname":"foo","age":102,"id":1}
```

And now Fumiko is 102!

We could also instead of calling #connect we could use a rails routes DSL to connect commands:

```ruby
require "foobara/rails_command_connector"

Foobara::CommandConnectors::RailsCommandConnector.new

require "foobara/rails/routes"

Rails.application.routes.draw do
  command CreateCapybara
  command IncrementAge
  command FindCapybara
end
```

This has the same effect as the previous code and is just a stylistic alternative.

#### Async Command Connectors

TODO

#### Scheduler Command Connectors

TODO

## Intermediate Foobara

### Metadata manifests for discoverability

Foobara concepts all have a manifest of metadata that can be queried programmatically.  This facilitates
automation tooling and abstracting away integration code.

Let's take a quick look at some metadata in our existing systems.

Let's for example ask our Capybara entity for its manifest:

```irb
> Capybara.foobara_manifest
==>
{:attributes_type=>
  {:type=>:attributes,
   :element_type_declarations=>
    {:id=>{:type=>:integer},
     :name=>{:description=>"Official name", :type=>:string},
     :nickname=>{:description=>"Informal name for friends", :type=>:string},
     :age=>{:description=>"The number of times this capybara has gone around the sun", :type=>:integer}},
   :required=>[:name, :age]},
 :organization_name=>"global_organization",
 :domain_name=>"global_domain",
 :model_name=>"Capybara",
 :model_base_class=>"Foobara::Entity",
 :model_class=>"Capybara",
 :entity_name=>"Capybara",
 :primary_key_attribute=>:id}
```

Let's ask our Rack connector for a list of commands it exposes:

```irb
> command_connector.foobara_manifest[:command].keys
==> [:CreateCapybara, :FindCapybara, :IncrementAge]
```

We can see all the different categories of concepts available by looking at the top-level keys:

```irb
> puts command_connector.foobara_manifest.keys.sort
command
domain
error
organization
processor
processor_class
type
```

### Remote Commands

One use of these metadata manifests is importing remote commands/orgs/domains/errors/types. This allows us to run
commands from other systems as if they were implemented locally.

Let's install foobara-remote-imports:

```
$ gem install foobara-remote-imports
```

And lLet's create a new script and import our various Capybara commands over HTTP:

```ruby
#!/usr/bin/env ruby

require "foobara"
require "foobara/remote_imports"

Foobara::RemoteImports::ImportCommand.run!(manifest_url: "http://localhost:9292/manifest", cache: true)

require "irb"
IRB.start(__FILE__)
```

Let's run this new script and play with it:

```
$ ./part_2b_remote_commands_import.rb
> capybara = FindCapybara.run!(id: 1)
==> #<Capybara:0x00007f6895bb2998 @attributes={:name=>"Fumiko", :nickname=>"foo", :age=>100, :id=>1}, @mutable=false>
> capybara.age
==> 100
```

Great! We can now move commands, types, etc, around between systems without needing to refactor calling code.  Even
errors work the same way:

```
> puts FindCapybara.run(id: "asdf").errors_sentence
At id: Cannot cast "asdf" to an integer. Expected it to be a Integer, or be a string of digits optionally with a minus sign in front
```

### Subcommands

Inevitably, we'll want one high-level domain operation to be able to invoke another high-level domain operation. And
because Foobara commands are the public interfaces to our systems/subsystems, we really really want to be able to do
this when a command needs a behavior from another domain as an implementation detail.

Let's create a command that calls another. Remember our `Add` command from earlier?
Let's implement a contrived Subtract command that is implemented using Add:

```ruby

class Subtract < Foobara::Command
  inputs do
    operand1 :integer, :required
    operand2 :integer, :required
  end

  result :integer

  depends_on Add

  def execute
    subtract_operands

    difference
  end

  attr_accessor :difference

  def subtract_operands
    self.difference = run_subcommand!(Add, operand1:, operand2: -operand2)
  end
end
```

We call our subcommand using `#run_subcommand!`. This will run the command and return the result. If an error occurs,
the errors from Add will be appended to our errors for Subtract, causing it to fail.

Note that we declare that Subtract depends on Add. We do this using `.depends_on`. This helps in a few ways.
For one, Subtract.possible_errors can include errors that might happen in Add.
This allows us to see a command dependencies using graphing tools and what-not and enforce a unidirectional
dependency graph of commands.

Let's play with it:

```ruby
> Subtract.run!(operand1: 5, operand2: 2)
==> 3
```

We get the answer we expected!

A little bit advanced but let's look at the possible errors for Subtract:

```irb
> Subtract.possible_errors.map(&:key).map(&:to_s).sort
==>
["add>data.cannot_cast",
 "add>data.missing_required_attribute",
 "add>data.operand1.cannot_cast",
 "add>data.operand1.missing_required_attribute",
 "add>data.operand2.cannot_cast",
 "add>data.operand2.missing_required_attribute",
 "add>data.unexpected_attributes",
 "data.cannot_cast",
 "data.missing_required_attribute",
 "data.operand1.cannot_cast",
 "data.operand1.missing_required_attribute",
 "data.operand2.cannot_cast",
 "data.operand2.missing_required_attribute",
 "data.unexpected_attributes"]
```

We can see some errors from Add here.  Note: we actually know in this case that we don't expect these errors to occur.
We could filter these out to improve the information to the outside world/tooling/generators but that's beyond
the intermediate level.

### Custom Errors

Speaking of errors, an intermediate Foobara skill is defining a custom error.

#### Input Errors

Let's make a DivideByZeroError as an example. First, let's make a command that would use it. Q: can you
guess which command we're going to make next? A: Divide!

```ruby
class Divide < Foobara::Command
  inputs do
    dividend :integer, :required
    divisor :integer, :required
  end

  result :integer

  depends_on Subtract

  def execute
    initialize_quotient_to_zero
    make_operands_positive_and_determine_if_result_is_negative

    until dividend_less_than_divisor?
      increment_quotient
      subtract_divisor_from_dividend
    end

    negate_quotient if negative_result?

    quotient
  end

  attr_accessor :negative_result, :quotient

  def make_operands_positive_and_determine_if_result_is_negative
    self.negative_result = false

    if dividend < 0
      self.dividend = -dividend
      self.negative_result = !negative_result
    end

    if divisor < 0
      self.divisor = -divisor
      self.negative_result = !negative_result
    end
  end

  def negate_quotient
    self.quotient = -quotient
  end

  def dividend_less_than_divisor?
    dividend < divisor
  end

  def negative_result?
    negative_result
  end

  def increment_quotient
    self.quotient += 1
  end

  def subtract_divisor_from_dividend
    self.dividend = run_subcommand!(Subtract, operand1: dividend, operand2: divisor)
  end

  def initialize_quotient_to_zero
    self.quotient = 0
  end

  attr_writer :dividend, :divisor

  def dividend
    @dividend || super
  end

  def divisor
    @divisor || super
  end
end
```

This one is pretty long because it has a more complex algorithm. Note how the #execute method
has a self-documenting form of the algorithm in it. That is a good best-practice when it comes to commands.
In a real project, this would be encapsulating a high-level domain operation. Having various levels
of abstraction of the algorithm mixed together can harm our ability to see what the domain
operation entails at a high-level.

Let's play with it:

```irb
> Divide.run!(dividend: 6, divisor: 7)
==> 0
> Divide.run!(dividend: 8, divisor: 7)
==> 1
> Divide.run!(dividend: 49, divisor: 7)
==> 7
```

We get the expected integer division results. However, if we pass
0 as the divisor, it will hang forever.

Time for our custom error!

```ruby
class Divide < Foobara::Command
  possible_input_error :divisor, :divide_by_zero, message: "Cannot divide by zero"

  ...
```

This is one way we can express a custom error for associated with a specific input.

Let's try it out!

```irb
> outcome = Divide.run(dividend: 49, divisor: 0)
==> #<Foobara::Outcome:0x00007f504d178e38...
        > outcome.success?
==> false
> outcome.errors_hash
==>
        {"data.divisor.divide_by_zero"=>
                 {:key=>"data.divisor.divide_by_zero",
                  :path=>[:divisor],
                  :runtime_path=>[],
                  :category=>:data,
                  :symbol=>:divide_by_zero,
                  :message=>"Cannot divide by zero",
                  :context=>{},
                  :is_fatal=>false}}
> outcome.errors_sentence
==> "Cannot divide by zero"
```

And we can see the error in the command's list of possible errors:

```irb
> Divide.possible_errors.map(&:key).map(&:to_s).grep /zero/
==> ["data.divisor.divide_by_zero"]
```

And of course, as expected, tooling has access to information about this error and the command's possible error through manifest
metadata:

```irb
> Foobara.manifest[:command][:Divide][:possible_errors]["data.divisor.divide_by_zero"][:error]
==> "Divide::DivideByZeroError"
> Foobara.manifest[:error][:"Divide::DivideByZeroError"][:parent]
==> [:command, "Divide"]
```

There's an alternative way to express these custom errors:

```ruby
class Divide < Foobara::Command
  class DivideByZeroError < Foobara::DataError
    def message
      "Cannot divide by zero"
    end
  end
  
  possible_input_error :divisor, DivideByZeroError
```

Both do the same thing.

#### Runtime Errors

Often, you a command will have to fail due to an error that isn't related to a specific input.  For these situations,
you want a runtime error.  Let's convert our DivideByZeroError to a runtime error just for demonstration purposes:

```ruby
class Divide < Foobara::Command
  possible_error :divide_by_zero, message: "Cannot divide by zero"

  def execute
    validate_divisor

    ...
  end

  def validate_divisor
    if divisor == 0
      add_runtime_error DivideByZeroError
    end
  end

  ...
```

And let's try it out:

```irb
> outcome = Divide.run(dividend: 49, divisor: 0)
==> #<Foobara::Outcome:0x00007f030fe3b8b8...
> outcome.success?
==> false
> outcome.errors_sentence
==> "Cannot divide by zero"
> outcome.errors_hash
==>
{"runtime.divide_by_zero"=>
  {:key=>"runtime.divide_by_zero",
   :path=>[],
   :runtime_path=>[],
   :category=>:runtime,
   :symbol=>:divide_by_zero,
   :message=>"Cannot divide by zero",
   :context=>{},
   :is_fatal=>false}}
```

Very similar behavior to before but this time it's a runtime error.

## Advanced Foobara

### Domain Mappers

We should really move our various commands into their proper orgs/domains now for the remaining advanced/expert
examples.

In an integer_math_server.rb file, let's put Add/Subtract/Divide and expose them via HTTP:

```ruby
#!/usr/bin/env ruby

require "foobara/rack_connector"
require "rackup/server"

module FoobaraDemo
  foobara_organization!

  module IntegerMath
    foobara_domain!

    class Add < Foobara::Command
      ...
end


command_connector = Foobara::CommandConnectors::Http::Rack.new
command_connector.connect(FoobaraDemo)

Rackup::Server.start(app: command_connector)
```

Note: here we have just connected the entire organization. This is just a lazy way for us to expose all commands.

Let's do the same for our capybara commands.
In a capy_cafe_server.rb file, let's put CreateCapybara/IncrementAge/FindCapybara and expose them via HTTP:

```ruby
#!/usr/bin/env ruby

require "foobara/local_files_crud_driver"
require "foobara/rack_connector"
require "rackup/server"

crud_driver = Foobara::LocalFilesCrudDriver.new
Foobara::Persistence.default_crud_driver = crud_driver

module FoobaraDemo
  foobara_organization!

  module CapyCafe
    foobara_domain!

    class Capybara < Foobara::Entity
      ...

command_connector = Foobara::CommandConnectors::Http::Rack.new

command_connector.connect(FoobaraDemo)

Rackup::Server.start(app: command_connector, Port: 9293)
```

We'll start this one on 9293 since it will have the same URL as our integer math server.

Now, let's come up with a contrived use-case for a domain mapper. Let's say there's some information about capybaras
in some other model in some other domain that we could import into our CapyCafe domain.

Let's code up such a domain/model in yet another file called capy_cafe_import.rb,
let's set import our other two domains:

```ruby
#!/usr/bin/env ruby

require "foobara/remote_imports"

[9292, 9293].each do |port|
  Foobara::RemoteImports::ImportCommand.run!(manifest_url: "http://localhost:#{port}/manifest")
end
```

And now let's define an Animal model that could be imported into our CapyCafe domain as a Capybara record:

```ruby
module FoobaraDemo
  module AnimalHouse
    foobara_domain!

    class Animal < Foobara::Model
      attributes do
        first_name :string
        last_name :string
        birthday :date
        species :symbol, one_of: %i[capybara cat tartigrade]
      end
    end
  end
end
```

And now let's define a domain mapper that knows how to map an AnimalHouse::Animal to a CapyCafe::Capybara:

```ruby
module FoobaraDemo
  module CapyCafe
    foobara_depends_on AnimalHouse

    class AnimalToCapybara < Foobara::DomainMapper
      from AnimalHouse::Animal
      to CreateCapybara

      def map(animal)
        age = birthday_to_age(animal.birthday)

        {
                name: "#{animal.first_name} #{animal.last_name}",
                age:
        }
      end

      def birthday_to_age(birthday)
        today = Date.today
        age = today.year - birthday.year
        birthday_this_year = Date.new(birthday.year + age, birthday.month, birthday.day)

        today < birthday_this_year ? age - 1 : age
      end
    end
  end
end
```

Note: that we have a bit of an unusual architecture here: we are defining CapyCafe commands in two different systems.
A point of Foobara is that regardless of how these commands are distributed calling code doesn't change as this
distribution changes.

Normally, we wouldn't make use of a domain mapper in isolation. Like everything else, it should be used in the context
of a command. But we can play with it directly:

```irb
$ ./animal_house_import.rb
> create_capybara_inputs = FoobaraDemo::CapyCafe::AnimalToCapybara.call(species: :capybara, first_name: "Barbara", last_name: "Doe", birthday: "1000-01-01")
==> {:name=>"Barbara Doe", :age=>1024}
> barbara = FoobaraDemo::CapyCafe::CreateCapybara.run!(create_capybara_inputs)
==> <Capybara:2>
> barbara.age
==> 1024
> barbara.id
==> 2
```

And we can increment Barbara's age now that she has been imported into our CapyCafe:

```irb
> FoobaraDemo::CapyCafe::IncrementAge.run!(capybara: barbara)
==> <Capybara:2>
> FoobaraDemo::CapyCafe::FindCapybara.run!(id: barbara)
==> <Capybara:2>
> FoobaraDemo::CapyCafe::FindCapybara.run!(id: barbara).age
==> 1025
```

Now let's create a command that makes use of our domain mapper which is the typical usage pattern:

```ruby
#!/usr/bin/env ruby

require "foobara/remote_imports"

[9292, 9293].each do |port|
  Foobara::RemoteImports::ImportCommand.run!(manifest_url: "http://localhost:#{port}/manifest")
end

module FoobaraDemo
  module AnimalHouse
    foobara_domain!
  end
end

module FoobaraDemo
  module AnimalHouse
    class Animal < Foobara::Model
      attributes do
        first_name :string
        last_name :string
        birthday :date
        species :symbol, one_of: %i[capybara cat tartigrade]
      end
    end
  end
end

module FoobaraDemo
  module CapyCafe
    class ImportAnimal < Foobara::Command
      class NotACapybara < Foobara::DataError
        context species: :symbol, animal: AnimalHouse::Animal

        def message
          "Can only import a capybara not a #{species}"
        end
      end

      inputs animal: AnimalHouse::Animal
      result Capybara

      possible_input_error :animal, NotACapybara

      depends_on CreateCapybara

      def execute
        create_capybara

        capybara
      end

      attr_accessor :capybara

      def validate
        species = animal.species

        unless species == :capybara
          add_input_error :animal, NotACapybara, animal: animal, species: species
        end
      end

      def create_capybara
        self.capybara = run_mapped_subcommand!(CreateCapybara, animal)
      end
    end
  end
end
```

Note that we can automatically map `animal` to CreateCapybara inputs by calling `#run_mapped_subcommand!`

Let's play with it:

```irb

```
TODO

### Code Generators

#### Generating a new Foobara Ruby project
#### Generating a new Foobara Typescript/React project
#### Generating commands, models, entities, types, domains, organizations, etc...

TODO

### Custom types

TODO

## Expert Foobara

### Callbacks

TODO

### Transactions in Commands

TODO

### Transactions in tests/console

TODO

### Custom crud drivers

TODO

### Custom command connectors

TODO

### Value processors

TODO

### Custom types from scratch

TODO

### Namespaces

TODO

# Additional learning materials/Documentation

* Overview and code demo videos:
  * https://foobara.com/videos
  * https://www.youtube.com/@FoobaraFlix
* YARD Docs
  * All docs combined: https://docs.foobara.com/all/
  * Per-repository docs: https://foobara.com/docs

# Contributing

Probably a good idea to reach out if you'd like to contribute code or documentation or other
forms of help. We could pair on what you have in mind and you could drive or at least we can make sure
it's a good use of time. I can be reached at azimux@gmail.com

You can contribute via a github pull request as is typical

Make sure the test suite and linter pass locally before opening a pull request

The build will fail if test coverage is below 100%

## Developing locally

You should be able to do the typical stuff:

```bash
git clone git@github.com:foobara/foobara
cd foobara
bundle
rake
```

And if the tests/linter pass then you could dive into modifying the code

## Monorepo Structure

Foobara is split up into many projects

Many are in separate repositories which you can see at: https://github.com/orgs/foobara/repositories

This repository, however, is a monorepo. Sometimes projects are extracted from here
into their own repositories. Each project in this repository has its own directory in the projects/ directory.

# Licensing

Foobara is licensed under the Mozilla Public License Version 2.0. Please see LICENSE.txt for more info.
