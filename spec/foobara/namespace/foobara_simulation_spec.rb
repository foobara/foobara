# types of scoped registration

# 1. extend a module/root or global namespace (Foobara)
# 2. all subclasses should be namespaces and autoregistered (Org/Domain/Command)
# 3. all instances are namespaces (Type)
# 4. explicit registration (Max)

Module.include Foobara::Namespace::NamespaceHelpers

module FoobaraSimulation
  module Foobara
    foobara_root_namespace!(ignore_modules: FoobaraSimulation)
  end

  # TODO: support concept of abstract classes...
  class Org
    extend ::Foobara::Scoped

    self.namespace = Foobara

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
    extend ::Foobara::Scoped

    self.namespace = Foobara

    extend ::Foobara::Namespace::IsNamespace
  end

  class Command
    extend ::Foobara::Namespace::IsNamespace
  end

  class Type
    include ::Foobara::Namespace::IsNamespace

    def initialize(symbol, parent_namespace = Foobara)
      initialize_foobara_namespace(symbol, accesses: [], parent_namespace:)
    end

    def add_processor(processor)
      processor.parent_namespace = self
      register(processor)
    end
  end

  class Processor
    extend ::Foobara::Scoped

    self.namespace = Foobara

    extend ::Foobara::Namespace::IsNamespace
  end

  # instances/subclasses
  class Error
    extend ::Foobara::Scoped

    class << self
      # TODO: get this junk into a module somehow...
      def inherited(klass)
        # why isn't this automated??
        ::Foobara::Namespace.autoregister(klass, default_parent: Foobara)
        super
      end
    end
  end

  class GlobalError < Error
  end

  class Max < Processor
    extend ::Foobara::Namespace::IsNamespace

    class TooBig < Error
    end
  end

  Integer = Type.new(:integer)
  Integer.add_processor(Max)

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
    it "finds the expected objects given certain paths", :focus do
      expect(FoobaraSimulation::OrgA.parent_namespace).to eq(FoobaraSimulation::Foobara)
      expect(FoobaraSimulation::OrgA.scoped_path).to eq(%w[OrgA])
      expect(FoobaraSimulation::OrgA.scoped_full_path).to eq(%w[OrgA])
      expect(FoobaraSimulation::Foobara.lookup_org("OrgA")).to eq(FoobaraSimulation::OrgA)
      expect(FoobaraSimulation::Foobara.lookup_org("::OrgA")).to eq(FoobaraSimulation::OrgA)

      expect(FoobaraSimulation::OrgA::DomainA.parent_namespace).to eq(FoobaraSimulation::OrgA)
      expect(FoobaraSimulation::OrgA::DomainA.scoped_path).to eq(%w[DomainA])
      expect(FoobaraSimulation::OrgA::DomainA.scoped_full_path).to eq(%w[OrgA DomainA])
      expect(FoobaraSimulation::OrgA::DomainA.scoped_full_name).to eq("::OrgA::DomainA")
      expect(
        FoobaraSimulation::Foobara.lookup_domain("OrgA::DomainA")
      ).to eq(FoobaraSimulation::OrgA::DomainA)
      expect(
        FoobaraSimulation::Foobara.lookup_domain("::OrgA::DomainA")
      ).to eq(FoobaraSimulation::OrgA::DomainA)

      expect(FoobaraSimulation::OrgA::DomainA.lookup_domain(:DomainA)).to eq(FoobaraSimulation::OrgA::DomainA)
      expect(FoobaraSimulation::OrgA::DomainA.lookup_domain("::DomainA")).to be_nil

      expect(FoobaraSimulation::OrgA::DomainA::CommandA.parent_namespace).to eq(FoobaraSimulation::OrgA::DomainA)
      expect(FoobaraSimulation::OrgA::DomainA::CommandA.scoped_path).to eq(%w[CommandA])
      expect(FoobaraSimulation::OrgA::DomainA::CommandA.scoped_full_path).to eq(%w[ OrgA DomainA
                                                                                    CommandA])
      expect(
        FoobaraSimulation::OrgA::DomainA::CommandA.scoped_full_name
      ).to eq("::OrgA::DomainA::CommandA")
      expect(
        FoobaraSimulation::Foobara.lookup_command("OrgA::DomainA::CommandA")
      ).to eq(FoobaraSimulation::OrgA::DomainA::CommandA)
      expect(
        FoobaraSimulation::Foobara.lookup_command("::OrgA::DomainA::CommandA")
      ).to eq(FoobaraSimulation::OrgA::DomainA::CommandA)

      expect(FoobaraSimulation::GlobalError.namespace).to eq(FoobaraSimulation::Foobara)
      expect(FoobaraSimulation::GlobalError.scoped_path).to eq(%w[GlobalError])
      expect(FoobaraSimulation::GlobalError.scoped_full_path).to eq(%w[GlobalError])
      expect(
        FoobaraSimulation::Foobara.lookup_error("GlobalError")
      ).to eq(FoobaraSimulation::GlobalError)
      expect(
        FoobaraSimulation::Foobara.lookup_error("::GlobalError")
      ).to eq(FoobaraSimulation::GlobalError)

      expect(
        FoobaraSimulation::OrgA::DomainB::CommandA::SomeError.namespace
      ).to eq(FoobaraSimulation::OrgA::DomainB::CommandA)

      expect(FoobaraSimulation::Integer.parent_namespace).to eq(FoobaraSimulation::Foobara)
      expect(FoobaraSimulation::Foobara.lookup_type("integer")).to eq(FoobaraSimulation::Integer)

      expect(FoobaraSimulation::Foobara.lookup_type("integer")).to eq(FoobaraSimulation::Integer)

      expect(FoobaraSimulation::Integer.lookup_processor("Max")).to eq(FoobaraSimulation::Max)
      expect(FoobaraSimulation::Integer.lookup_processor("Max")).to eq(FoobaraSimulation::Max)
      expect(FoobaraSimulation::Foobara.lookup_processor("integer::Max")).to eq(FoobaraSimulation::Max)

      expect(FoobaraSimulation::Max.lookup_error("TooBig")).to eq(FoobaraSimulation::Max::TooBig)
      expect(
        FoobaraSimulation::Foobara.lookup_error("integer::Max::TooBig")
      ).to eq(FoobaraSimulation::Max::TooBig)
    end
  end
end
