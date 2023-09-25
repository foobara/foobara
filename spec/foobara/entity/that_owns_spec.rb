RSpec.describe Foobara::Entity do
  # Entity types:
  #
  # one-to-one (default for foo: Bar attribute)
  # one-to-many (default for foo: [Bar] attribute)
  # many-to-one
  # many-to-many
  #
  # .that_own is for many-to-*
  # .that_owns is for one-to-*
  #
  # To specify many-to-* one must add:
  #
  # associations: {
  #   foo: {
  #     cardinality: "many-to-one"
  #   }
  # }
  #
  # otherwise an exception will be thrown from .that_own
  describe ".that_owns" do
    let(:entity_class) do
      stub_class = ->(klass) { stub_const(klass.name, klass) }

      Class.new(Foobara::Entity) do
        class << self
          def name
            "SomeEntity"
          end
        end

        stub_class.call(self)

        attributes pk: :integer,
                   foo: :integer,
                   bar: :symbol

        primary_key :pk
      end
    end

    let(:aggregate_class) do
      # TODO: refactor into a rspec helper for creating a properly stubbed class with a name
      stub_class = ->(klass) { stub_const(klass.name, klass) }

      Class.new(Foobara::Entity) do
        class << self
          def name
            "SomeAggregate"
          end
        end

        stub_class.call(self)

        attributes pk: :integer,
                   foo: :integer,
                   some_entities: [SomeEntity]

        primary_key :pk
      end
    end
  end
end

=begin
assignment
package
employee
applicant

employee
user

employee is many-to-many with packages through

class Assignment
  attributes id: :integer,
             package: Package

  primary_key :id
end

class Employee
  attributes id: :integer,
             user: User,
             assignments: [Assignment],
             past_assignments: [Assignment]

  primary_key :id
end

class User
  attributes id: :integer,
             name: :string

  primary_key :id
end

class Package
  attributes id: :integer,
             applicant: Applicant

  primary_key :id
end

class Applicant
  attributes id: :integer.
             name: :string

  primary_key :id
end

=end
