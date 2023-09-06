RSpec.describe Foobara::Domain do
  after do
    described_class.reset_unprocessed_command_classes
    described_class.reset_all
    Foobara::Organization.reset_all
  end

  let(:domain) { domain_module.foobara_domain }
  let(:organization) { organization_module.foobara_organization }

  context "with simple command" do
    let(:domain_module) {
      Module.new do
        class << self
          def name
            "SomeDomain"
          end

          foobara_domain!
        end
      end
    }

    let(:command_class) {
      Class.new(Foobara::Command) do
        class << self
          def name
            "SomeDomain::SomeCommand"
          end
        end
      end
    }

    let(:organization_module) do
      Module.new do
        class << self
          def name
            "SomeOrg"
          end

          foobara_organization!
        end
      end
    end

    before do
      stub_const(organization_module.name, organization_module)
      stub_const(domain_module.name, domain_module)
      expect(domain).to be_a(described_class)
      stub_const(command_class.name, command_class)
    end

    describe "#full_domain_name" do
      subject { domain.full_domain_name }

      it { is_expected.to eq("SomeDomain") }
    end

    describe "#full_domain_symbol" do
      subject { domain.full_domain_symbol }

      it { is_expected.to eq(:some_domain) }
    end

    context "with organization" do
      let(:domain_module) {
        Module.new do
          class << self
            def name
              "SomeOrg::SomeDomain"
            end

            foobara_domain!
          end
        end
      }

      let(:command_class) {
        Class.new(Foobara::Command) do
          class << self
            def name
              "SomeOrg::SomeDomain::SomeCommand"
            end
          end
        end
      }

      describe "#full_domain_name" do
        subject { domain.full_domain_name }

        it { is_expected.to eq("SomeOrg::SomeDomain") }
      end

      describe "#full_domain_symbol" do
        subject { domain.full_domain_symbol }

        it { is_expected.to eq(:"some_org::some_domain") }
      end

      # TODO: belongs elsewhere
      describe "#owns_domain?" do
        subject { organization.owns_domain?(domain) }

        it { is_expected.to be(true) }
      end

      describe "#command_classes" do
        subject { domain.command_classes }

        it { is_expected.to eq([command_class]) }
      end
    end
  end
end
