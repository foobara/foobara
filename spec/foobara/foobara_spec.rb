RSpec.describe Foobara do
  describe ".raise_if_production!" do
    let(:method_name) { "reset_alls" }
    let(:original_env) { ENV.fetch("FOOBARA_ENV", nil) }

    after do
      ENV["FOOBARA_ENV"] = original_env
    end

    context "when FOOBARA_ENV is nil" do
      stub_env_var("FOOBARA_ENV", nil)

      it "raises MethodCantBeCalledInProductionError" do
        expect {
          described_class.raise_if_production!(method_name)
        }.to raise_error(
          Foobara::MethodCantBeCalledInProductionError,
          "#{method_name} can't be called in production!"
        )
      end
    end

    context "when in production environment" do
      stub_env_var("FOOBARA_ENV", "production")

      it "raises MethodCantBeCalledInProductionError" do
        expect {
          described_class.raise_if_production!(method_name)
        }.to raise_error(
          Foobara::MethodCantBeCalledInProductionError,
          "#{method_name} can't be called in production!"
        )
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
      before do
        ENV["FOOBARA_ENV"] = "development"
      end

      it "doesn't raise MethodCantBeCalledInProductionError" do
        expect {
          described_class.raise_if_production!(method_name)
        }.to_not raise_error
      end
    end
  end
end
