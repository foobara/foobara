class Module
  # simplecov:disable
  def foobara_delegate(*method_names, to:, allow_nil: false)
    warn "[DEPRECATION] `foobara_delegate` is deprecated and will be removed in future versions"

    method_names.each do |method_name|
      define_method method_name do |*args, **opts, &block|
        target = to.is_a?(::Symbol) || to.is_a?(::String) ? __send__(to) : to
        return nil if target.nil? && allow_nil

        target.__send__(method_name, *args, **opts, &block)
      end
    end
  end
  # simplecov:enable
end
