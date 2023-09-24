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
end
