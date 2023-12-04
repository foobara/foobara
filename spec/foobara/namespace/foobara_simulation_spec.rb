module FoobaraSimulation
  module Foobara
    class << self
      def scoped_path
        []
      end
    end

    extend ::Foobara::Namespace::IsNamespace
  end

  class Org
    # TODO: may as well have foobara_namespace! helper...
    extend ::Foobara::Namespace::IsNamespace

    class << self
      def inherited(klass)
        klass.parent_namespace ||= Foobara
        super
      end
    end
  end

  class Domain
    extend ::Foobara::Namespace::IsNamespace
  end

  class Command
    extend ::Foobara::Namespace::IsNamespace
  end

  class Type
    include ::Foobara::Namespace::IsNamespace

    attr_accessor :processors

    def initialize(symbol)
      self.scoped_name = symbol.to_s
    end
  end

  class Processor
    extend ::Foobara::Namespace::IsNamespace
  end

  # instances/subclasses
  class Error
    extend ::Foobara::Scoped
  end

  class GlobalError < Error
  end

  class Max < Processor
    class TooBig < Error
    end
  end

  Integer = Type.new(:integer)
  Integer.processors = [Max]

  $stop = true

  class OrgA < Org
    class DomainA < Domain
      CustomType = Type.new(:custom_type)

      class CommandA < Command
      end

      class CommandB < Command
      end
    end

    class DomainB < Domain
      CustomType = Type.new(:custom_type)

      class CommandA < Command
        class SomeError < Error
        end
      end

      class CommandB < Command
      end

      module Foo
        module Bar
          class CommandA < Command
          end
        end
      end
    end
  end

  class OrgB < Org
    class DomainA < Domain
      class CommandA < Command
      end

      class CommandB < Command
      end
    end

    class DomainB < Domain
      class CommandA < Command
      end

      class CommandB < Command
      end

      module Foo
        module Bar
          class CommandA < Command
          end
        end
      end
    end
  end

  class GlobalDomain < Domain
    class DomainA < Domain
      class CommandA < Command
      end

      class CommandB < Command
      end
    end

    class DomainB < Domain
      class CommandA < Command
      end

      class CommandB < Command
      end

      module Foo
        module Bar
          class CommandA < Command
          end
        end
      end
    end
  end

  module Foobara
    add_category_for_subclass_of(:org, Org)
    add_category_for_subclass_of(:domain, Domain)
    add_category_for_subclass_of(:command, Command)
    add_category_for_instance_of(:type, Type)
    add_category_for_subclass_of(:processor, Processor)
  end
end

RSpec.describe Foobara::Namespace, :focus do
  describe "#lookup_*" do
    it "finds the expected objects given certain paths" do
      expect(FoobaraSimulation::OrgA.parent_namespace).to eq(FoobaraSimulation::Foobara)
      expect(FoobaraSimulation::OrgA.scoped_path).to eq(%w[FoobaraSimulation OrgA])
      expect(FoobaraSimulation::Foobara.lookup_org("FoobaraSimulation::OrgA")).to eq(FoobaraSimulation::OrgA)
      expect(FoobaraSimulation::Foobara.lookup_org("::FoobaraSimulation::OrgA")).to eq(FoobaraSimulation::OrgA)
    end
  end
end
