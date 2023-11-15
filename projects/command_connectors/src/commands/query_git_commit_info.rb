module Foobara
  module CommandConnectors
    module Commands
      # NOTE: this assumes that the following has been executed to generate the `git_commit_info.json` file:
      #
      # git show -s --format='{"commit": "%H", "author": "%an <%ae>", "date": "%ad", "message": "%s"}' \
      #   HEAD > $1/git_commit_info.json
      class QueryGitCommitInfo < Foobara::Command
        GIT_COMMIT_INFO_FILE = "git_commit_info.json".freeze

        # TODO: creating these types of error classes should be much much easier!
        class GitCommitInfoFileNotFoundError < Foobara::RuntimeError
          class << self
            def message
              format = '{"commit": "%H", "author": "%an <%ae>", "date": "%ad", "message": "%s"}'

              <<~HERE
                Could not find file: #{GIT_COMMIT_INFO_FILE}.#{" "}
                Are you sure you are executing the following in the right place in your infrastructure?

                  git show -s --format='#{format}' HEAD > git_commit_info.json

              HERE
            end

            def context_type_declaration
              {}
            end

            def context
              {}
            end
          end
        end

        possible_error GitCommitInfoFileNotFoundError

        result commit: :string,
               author: :string,
               date: :string,
               message: :string

        def execute
          validate_git_commit_info_exists
          load_git_commit_info

          git_commit_info
        end

        attr_accessor :commit,
                      :author,
                      :date,
                      :message

        def validate_git_commit_info_exists
          unless File.exist?(GIT_COMMIT_INFO_FILE)
            add_runtime_error GitCommitInfoFileNotFoundError
          end
        end

        def load_git_commit_info
          git_commit_info = JSON.parse(File.read(GIT_COMMIT_INFO_FILE))

          self.commit = git_commit_info["commit"]
          self.author = git_commit_info["author"]
          self.date = git_commit_info["date"]
          self.message = git_commit_info["message"]
        end

        def git_commit_info
          {
            commit:,
            author:,
            date:,
            message:
          }
        end
      end
    end
  end
end
