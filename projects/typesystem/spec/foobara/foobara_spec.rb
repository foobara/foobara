RSpec.describe Foobara do
  describe ".raise_if_production!" do
    def my_reset_method
      described_class.raise_if_production!
    end

    context "when FOOBARA_ENV is nil" do
      stub_env_var("FOOBARA_ENV", nil)

      it "raises MethodCantBeCalledInProductionError and infers method name" do
        expect {
          my_reset_method
        }.to raise_error(Foobara::MethodCantBeCalledInProductionError, /my_reset_method/)
      end

      it "prints a deprecation warning if method name is passed explicitly" do
        expect {
          expect {
            described_class.raise_if_production!("some_method")
          }.to raise_error(Foobara::MethodCantBeCalledInProductionError, "some_method")
        }.to output(/DEPRECATION WARNING/).to_stderr
      end
    end

    context "when in production environment" do
      stub_env_var("FOOBARA_ENV", "production")

      it "raises MethodCantBeCalledInProductionError" do
        expect {
          my_reset_method
        }.to raise_error(Foobara::MethodCantBeCalledInProductionError, /my_reset_method/)
      end
    end

    context "when in test environment" do
      stub_env_var("FOOBARA_ENV", "test")

      it "doesn't raise MethodCantBeCalledInProductionError" do
        expect {
          my_reset_method
        }.to_not raise_error
      end
    end

    context "when in development environment" do
      stub_env_var("FOOBARA_ENV", "development")

      it "doesn't raise MethodCantBeCalledInProductionError" do
        expect {
          my_reset_method
        }.to_not raise_error
      end
    end
  end
end
