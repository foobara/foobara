module Foobara
  class Command
    include CommandPatternImplementation
    # Maybe make ShortcutForRun optional and maybe even move it to a different repository?
    include Concerns::ShortcutForRun
  end
end
