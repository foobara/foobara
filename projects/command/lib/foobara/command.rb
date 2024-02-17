class Foobara::Command
  class << self
    def install!
      Foobara.foobara_add_category_for_subclass_of(:command, self)
    end
  end
end
