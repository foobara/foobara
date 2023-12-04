RSpec.describe Foobara::Namespace do
  after do
    Object.send(:remove_const, :FoobaraSimulation)
  end

  before do
    # rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
    module FoobaraSimulation
      module Foobara
        foobara_root_namespace!(ignore_modules: FoobaraSimulation)
      end

      # TODO: support concept of abstract classes...
      class Org
        foobara_subclasses_are_namespaces!(default_parent: Foobara, autoregister: true)
      end

      class Domain
        foobara_subclasses_are_namespaces!(default_parent: Foobara, autoregister: true)
      end

      class Command
        foobara_subclasses_are_namespaces!(default_parent: Foobara, autoregister: true)
      end

      class Type
        foobara_instances_are_namespaces!

        def add_processor(processor)
          processor.parent_namespace = self
          register(processor)
        end

        def initialize(scoped_path)
          self.scoped_path = ::Foobara::Util.array(scoped_path)
          super
        end
      end

      class Processor
        !foobara_subclasses_are_namespaces!(default_parent: Foobara)
      end

      class Error
        foobara_autoregister_subclasses(default_namespace: Foobara)
      end

      module Foobara
        add_category_for_subclass_of(:org, Org)
        add_category_for_subclass_of(:domain, Domain)
        add_category_for_subclass_of(:command, Command)
        add_category_for_instance_of(:type, Type)
        add_category_for_subclass_of(:processor, Processor)
        add_category_for_subclass_of(:error, Error)
      end

      class GlobalError < Error
      end

      Integer = Type.new(:integer)
      Integer.parent_namespace = Foobara
      Foobara.register(Integer)

      class Max < Processor
        class TooBig < Error
        end
      end

      Integer.add_processor(Max)

      class OrgA < Org
        class DomainA < Domain
          CustomType = Type.new(:custom_type)
          register(CustomType)

          class CommandA < Command
          end

          class CommandB < Command
          end
        end

        class DomainB < Domain
          CustomType = Type.new(:custom_type)
          register(CustomType)

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
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
  end

  describe "#lookup_*" do
    it "finds the expected objects given certain paths" do
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
      expect(FoobaraSimulation::OrgA::DomainA::CommandA.scoped_full_path).to eq(%w[OrgA DomainA CommandA])
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
      expect(FoobaraSimulation::Foobara.lookup_type("::integer")).to eq(FoobaraSimulation::Integer)

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
