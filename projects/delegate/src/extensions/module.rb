class Module
    def foobara_delegate(*method_names, to:, allow_nil: false)
      method_names.each do |method_name|
        define_method method_name do |*args, **opts, &block|
          target = to.is_a?(::Symbol) || to.is_a?(::String) ? send(to) : to
          return nil if target.nil? && allow_nil
  
          target.send(method_name, *args, **opts, &block)
        end
      end
    end
end