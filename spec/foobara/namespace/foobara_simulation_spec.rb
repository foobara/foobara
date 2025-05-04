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
          processor.foobara_parent_namespace = self
          foobara_register(processor)
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
        foobara_add_category_for_subclass_of(:org, Org)
        foobara_add_category_for_subclass_of(:domain, Domain)
        foobara_add_category_for_subclass_of(:command, Command)
        foobara_add_category_for_instance_of(:type, Type)
        foobara_add_category_for_subclass_of(:processor, Processor)
        foobara_add_category_for_subclass_of(:error, Error)
      end

      class GlobalError < Error
      end

      Integer = Type.new(:integer)
      Integer.foobara_parent_namespace = Foobara
      Foobara.foobara_register(Integer)

      class Max < Processor
        class TooBig < Error
        end
      end

      Integer.add_processor(Max)

      class OrgA < Org
        class DomainA < Domain
          CustomType = Type.new(:custom_type)
          foobara_register(CustomType)

          class CommandA < Command
          end

          class CommandB < Command
          end
        end

        class DomainB < Domain
          CustomType = Type.new(:custom_type)
          foobara_register(CustomType)

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
      attributes = FoobaraSimulation::OrgA::DomainA.foobara_lookup("::attributes")
      expect(attributes).to be(Foobara::BuiltinTypes[:attributes])

      expect(FoobaraSimulation::OrgA.foobara_parent_namespace).to eq(FoobaraSimulation::Foobara)
      expect(FoobaraSimulation::OrgA.scoped_path).to eq(["OrgA"])
      expect(FoobaraSimulation::OrgA.scoped_full_path).to eq(["OrgA"])
      expect(FoobaraSimulation::Foobara.foobara_lookup_org("OrgA")).to eq(FoobaraSimulation::OrgA)
      expect(FoobaraSimulation::Foobara.foobara_lookup_org("::OrgA")).to eq(FoobaraSimulation::OrgA)

      expect(FoobaraSimulation::OrgA::DomainA.foobara_parent_namespace).to eq(FoobaraSimulation::OrgA)
      expect(FoobaraSimulation::OrgA::DomainA.scoped_path).to eq(["DomainA"])
      expect(FoobaraSimulation::OrgA::DomainA.scoped_full_path).to eq(["OrgA", "DomainA"])
      expect(FoobaraSimulation::OrgA::DomainA.scoped_full_name).to eq("OrgA::DomainA")
      expect(FoobaraSimulation::OrgA::DomainA.scoped_absolute_name).to eq("::OrgA::DomainA")
      expect(
        FoobaraSimulation::Foobara.foobara_lookup_domain("OrgA::DomainA")
      ).to eq(FoobaraSimulation::OrgA::DomainA)
      expect(
        FoobaraSimulation::Foobara.foobara_lookup_domain("::OrgA::DomainA")
      ).to eq(FoobaraSimulation::OrgA::DomainA)

      expect(FoobaraSimulation::OrgA::DomainA.foobara_lookup_domain(:DomainA)).to eq(FoobaraSimulation::OrgA::DomainA)
      expect(FoobaraSimulation::OrgA::DomainA.foobara_lookup_domain("::DomainA")).to be_nil

      expect(
        FoobaraSimulation::OrgA::DomainA::CommandA.foobara_parent_namespace
      ).to eq(FoobaraSimulation::OrgA::DomainA)
      expect(FoobaraSimulation::OrgA::DomainA::CommandA.scoped_path).to eq(["CommandA"])
      expect(FoobaraSimulation::OrgA::DomainA::CommandA.scoped_full_path).to eq(["OrgA", "DomainA", "CommandA"])
      expect(FoobaraSimulation::OrgA::DomainA::CommandA.scoped_full_name).to eq("OrgA::DomainA::CommandA")
      expect(FoobaraSimulation::OrgA::DomainA::CommandA.scoped_absolute_name).to eq("::OrgA::DomainA::CommandA")
      expect(
        FoobaraSimulation::Foobara.foobara_lookup_command("OrgA::DomainA::CommandA")
      ).to eq(FoobaraSimulation::OrgA::DomainA::CommandA)
      expect(
        FoobaraSimulation::Foobara.foobara_lookup_command("::OrgA::DomainA::CommandA")
      ).to eq(FoobaraSimulation::OrgA::DomainA::CommandA)

      expect(FoobaraSimulation::GlobalError.scoped_namespace).to eq(FoobaraSimulation::Foobara)
      expect(FoobaraSimulation::GlobalError.scoped_path).to eq(["GlobalError"])
      expect(FoobaraSimulation::GlobalError.scoped_full_path).to eq(["GlobalError"])
      expect(
        FoobaraSimulation::Foobara.foobara_lookup_error("GlobalError")
      ).to eq(FoobaraSimulation::GlobalError)
      expect(
        FoobaraSimulation::Foobara.foobara_lookup_error("::GlobalError")
      ).to eq(FoobaraSimulation::GlobalError)

      expect(
        FoobaraSimulation::OrgA::DomainB::CommandA::SomeError.scoped_namespace
      ).to eq(FoobaraSimulation::OrgA::DomainB::CommandA)

      expect(FoobaraSimulation::Integer.foobara_parent_namespace).to eq(FoobaraSimulation::Foobara)
      expect(FoobaraSimulation::Foobara.foobara_lookup_type("integer")).to eq(FoobaraSimulation::Integer)
      expect(FoobaraSimulation::Foobara.foobara_lookup_type("::integer")).to eq(FoobaraSimulation::Integer)

      expect(FoobaraSimulation::Integer.foobara_lookup_processor("Max")).to eq(FoobaraSimulation::Max)
      expect(FoobaraSimulation::Integer.foobara_lookup_processor("Max")).to eq(FoobaraSimulation::Max)
      expect(FoobaraSimulation::Foobara.foobara_lookup_processor("integer::Max")).to eq(FoobaraSimulation::Max)

      expect(FoobaraSimulation::Max.foobara_lookup_error("TooBig")).to eq(FoobaraSimulation::Max::TooBig)
      expect(
        FoobaraSimulation::Foobara.foobara_lookup_error("integer::Max::TooBig")
      ).to eq(FoobaraSimulation::Max::TooBig)

      expect(FoobaraSimulation::Foobara.foobara_all).to contain_exactly(
        FoobaraSimulation::OrgA,
        FoobaraSimulation::OrgA::DomainA,
        FoobaraSimulation::OrgA::DomainA::CommandA,
        FoobaraSimulation::OrgA::DomainA::CommandB,
        FoobaraSimulation::OrgA::DomainA::CustomType,
        FoobaraSimulation::OrgA::DomainB,
        FoobaraSimulation::OrgA::DomainB::CommandA,
        FoobaraSimulation::OrgA::DomainB::CommandA::SomeError,
        FoobaraSimulation::OrgA::DomainB::CommandB,
        FoobaraSimulation::OrgA::DomainB::Foo::Bar::CommandA,
        FoobaraSimulation::OrgA::DomainB::CustomType,
        FoobaraSimulation::OrgB,
        FoobaraSimulation::OrgB::DomainA,
        FoobaraSimulation::OrgB::DomainA::CommandA,
        FoobaraSimulation::OrgB::DomainA::CommandB,
        FoobaraSimulation::OrgB::DomainB,
        FoobaraSimulation::OrgB::DomainB::CommandA,
        FoobaraSimulation::OrgB::DomainB::CommandB,
        FoobaraSimulation::OrgB::DomainB::Foo::Bar::CommandA,
        FoobaraSimulation::GlobalDomain,
        FoobaraSimulation::GlobalDomain::CommandA,
        FoobaraSimulation::GlobalDomain::CommandB,
        FoobaraSimulation::GlobalDomain::Foo::Bar::CommandA,
        FoobaraSimulation::GlobalError,
        FoobaraSimulation::Integer,
        FoobaraSimulation::Max,
        FoobaraSimulation::Max::TooBig
      )
    end

    context "with relaxed mode" do
      it "can find scoped object without prefixes" do
        expect(
          FoobaraSimulation::Foobara.foobara_lookup("TooBig", mode: Foobara::Namespace::LookupMode::RELAXED)
        ).to eq(FoobaraSimulation::Max::TooBig)
      end
    end
  end
end
