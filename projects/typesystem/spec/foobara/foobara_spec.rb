RSpec.describe Foobara do
  describe ".raise_if_production!" do
    let(:method_name) { "reset_alls" }

    context "when FOOBARA_ENV is nil" do
      stub_env_var("FOOBARA_ENV", nil)

      it "raises MethodCantBeCalledInProductionError" do
        expect {
          described_class.raise_if_production!(method_name)
        }.to raise_error(Foobara::MethodCantBeCalledInProductionError)
      end
    end

    context "when in production environment" do
      stub_env_var("FOOBARA_ENV", "production")

      it "raises MethodCantBeCalledInProductionError" do
        expect {
          described_class.raise_if_production!(method_name)
        }.to raise_error(Foobara::MethodCantBeCalledInProductionError)
      end
    end

    context "when in test environment" do
      stub_env_var("FOOBARA_ENV", "test")

      it "doesn't raise MethodCantBeCalledInProductionError" do
        expect {
          described_class.raise_if_production!(method_name)
        }.to_not raise_error
      end
    end

    context "when in development environment" do
      stub_env_var("FOOBARA_ENV", "development")

      it "doesn't raise MethodCantBeCalledInProductionError" do
        expect {
          described_class.raise_if_production!(method_name)
        }.to_not raise_error
      end
    end
  end
end
