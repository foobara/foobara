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

    def initialize(symbol, namespace = Foobara)
      self.scoped_name = symbol.to_s
      namespace.register(self)
    end
  end

  class Processor
    extend ::Foobara::Namespace::IsNamespace
  end

  # instances/subclasses
  class Error
    extend ::Foobara::Scoped

    class << self
      # TODO: get this junk into a module somehow...
      def inherited(klass)
        ::Foobara::Namespace.autoregister(klass, default_parent: Foobara)
      end
    end
  end

  class GlobalError < Error
  end

  class Max < Processor
    class TooBig < Error
    end
  end

  Integer = Type.new(:integer)
  Integer.processors = [Max]

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
    add_category_for_subclass_of(:error, Error)
  end
end

RSpec.describe Foobara::Namespace do
  describe "#lookup_*" do
    it "finds the expected objects given certain paths" do
      expect(FoobaraSimulation::OrgA.parent_namespace).to eq(FoobaraSimulation::Foobara)
      expect(FoobaraSimulation::OrgA.scoped_path).to eq(%w[FoobaraSimulation OrgA])
      expect(FoobaraSimulation::OrgA.scoped_full_path).to eq(%w[FoobaraSimulation OrgA])
      expect(FoobaraSimulation::Foobara.lookup_org("FoobaraSimulation::OrgA")).to eq(FoobaraSimulation::OrgA)
      expect(FoobaraSimulation::Foobara.lookup_org("::FoobaraSimulation::OrgA")).to eq(FoobaraSimulation::OrgA)

      expect(FoobaraSimulation::OrgA::DomainA.parent_namespace).to eq(FoobaraSimulation::OrgA)
      expect(FoobaraSimulation::OrgA::DomainA.scoped_path).to eq(%w[DomainA])
      expect(FoobaraSimulation::OrgA::DomainA.scoped_full_path).to eq(%w[FoobaraSimulation OrgA DomainA])
      expect(FoobaraSimulation::OrgA::DomainA.scoped_full_name).to eq("::FoobaraSimulation::OrgA::DomainA")
      expect(FoobaraSimulation::Foobara.lookup_domain("FoobaraSimulation::OrgA::DomainA")).to eq(FoobaraSimulation::OrgA::DomainA)
      expect(FoobaraSimulation::Foobara.lookup_domain("::FoobaraSimulation::OrgA::DomainA")).to eq(FoobaraSimulation::OrgA::DomainA)

      expect(FoobaraSimulation::OrgA::DomainA.lookup_domain("DomainA")).to eq(FoobaraSimulation::OrgA::DomainA)
      expect(FoobaraSimulation::OrgA::DomainA.lookup_domain("::DomainA")).to be_nil

      expect(FoobaraSimulation::OrgA::DomainA::CommandA.parent_namespace).to eq(FoobaraSimulation::OrgA::DomainA)
      expect(FoobaraSimulation::OrgA::DomainA::CommandA.scoped_path).to eq(%w[CommandA])
      expect(FoobaraSimulation::OrgA::DomainA::CommandA.scoped_full_path).to eq(%w[FoobaraSimulation OrgA DomainA
                                                                                   CommandA])
      expect(FoobaraSimulation::OrgA::DomainA::CommandA.scoped_full_name).to eq("::FoobaraSimulation::OrgA::DomainA::CommandA")
      expect(FoobaraSimulation::Foobara.lookup_command("FoobaraSimulation::OrgA::DomainA::CommandA")).to eq(FoobaraSimulation::OrgA::DomainA::CommandA)
      expect(FoobaraSimulation::Foobara.lookup_command("::FoobaraSimulation::OrgA::DomainA::CommandA")).to eq(FoobaraSimulation::OrgA::DomainA::CommandA)

      expect(FoobaraSimulation::GlobalError.namespace).to eq(FoobaraSimulation::Foobara)
      expect(FoobaraSimulation::GlobalError.scoped_path).to eq(%w[FoobaraSimulation GlobalError])
      expect(FoobaraSimulation::GlobalError.scoped_full_path).to eq(%w[FoobaraSimulation GlobalError])
      expect(FoobaraSimulation::Foobara.lookup_error("FoobaraSimulation::GlobalError")).to eq(FoobaraSimulation::GlobalError)
      expect(FoobaraSimulation::Foobara.lookup_error("::FoobaraSimulation::GlobalError")).to eq(FoobaraSimulation::GlobalError)

      expect(FoobaraSimulation::OrgA::DomainB::CommandA::SomeError.namespace).to eq(FoobaraSimulation::OrgA::DomainB::CommandA)

      expect(FoobaraSimulation::Integer.parent_namespace).to eq(FoobaraSimulation::Foobara)
      expect(FoobaraSimulation::Foobara.lookup_type("integer")).to eq(FoobaraSimulation::Integer)
    end
  end
end
