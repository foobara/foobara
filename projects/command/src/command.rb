module Foobara
  class Command < Service
    # Maybe make ShortcutForRun optional and maybe even move it to a different repository?
    include Concerns::ShortcutForRun
  end
end
