module RspecHelpers
  module Stubs
    module ClassMethods
      def stub_env_vars(env_vars)
        env_vars.each_pair do |env_var, value|
          stub_env_var(env_var, value)
        end
      end

      def stub_env_var(env_var, value)
        before do
          stub_env_var(env_var, value)
        end
      end
    end

    def stub_env_vars(env_vars)
      env_vars.each_pair do |env_var, value|
        stub_env_var(env_var, value)
      end
    end

    def stub_env_var(env_var, value)
      env_var = env_var.to_s

      unless self.class.metadata[:env_stubbed]
        install_env_stubs
      end

      self.class.metadata[:env_stubbed][env_var] = value
    end

    private

    def install_env_stubs
      env_stubbed = {}

      self.class.metadata[:env_stubbed] = env_stubbed
      self.class.after do
        self.class.metadata.delete(:env_stubbed)
      end

      allow(ENV).to receive(:fetch).and_wrap_original do |original_method, key, default|
        if env_stubbed.key?(key)
          env_stubbed[key]
        else
          original_method.call(key, default)
        end
      end
      allow(ENV).to receive(:[]).and_wrap_original do |original_method, key|
        if env_stubbed.key?(key)
          env_stubbed[key]
        else
          original_method.call(key)
        end
      end
      allow(ENV).to receive(:each).and_wrap_original do |original_method, &block|
        original_method.call(&block)
        env_stubbed.each(&block)

        ENV
      end
      allow(ENV).to receive(:each_key).and_wrap_original do |original_method, &block|
        original_method.call(&block)
        env_stubbed.each_key(&block)

        ENV
      end
      allow(ENV).to receive(:each_value).and_wrap_original do |original_method, &block|
        original_method.call(&block)
        env_stubbed.each_value(&block)

        ENV
      end
      allow(ENV).to receive(:keys).and_wrap_original do |original_method, &block|
        original_method.call(&block) | env_stubbed.keys
      end
      allow(ENV).to receive(:values).and_wrap_original do |original_method, &block|
        original_method.call(&block) | env_stubbed.values
      end
    end
  end
end

RSpec.configure do |c|
  c.extend RspecHelpers::Stubs::ClassMethods
  c.include RspecHelpers::Stubs
end
