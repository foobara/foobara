#!/usr/bin/env ruby

require "English"

class ExtractRepo
  attr_reader :repo_url, :paths

  def initialize(repo_url, paths)
    self.repo_url = repo_url
    self.paths = paths
  end

  def execute
    mk_extract_dir
    rm_old_repo

    clone_repo
    determine_paths
  end

  def chdir(&)
    Dir.chdir(extract_dir, &)
  end

  def extract_dir
    "~/tmp/extract/"
  end

  def repo_dir
    File.join(extract_dir,  repo_name)
  end

  def repo_name
    File.basename(repo_url, ".git")
  end

  def mk_extract_dir
    sh "mkdir -p #{extract_dir}"
  end

  def rm_old_repo
    sh "rm -rf #{repo_dir}"
  end

  def clone_repo
    Dir.chdir extract_dir do
      sh "git clone #{repo_url}"
    end
  end

  def determine_paths
    Dir.chdir repo_dir do
      paths.each do |path|
      end
    end
  end

  def sh(cmd)
    result = `#{cmd}`

    unless $CHILD_STATUS.success?
      raise "Command #{cmd} failed with status #{$CHILD_STATUS.exitstatus}: #{result}"
    end
  end
end

=begin
a_to_s() {
  local a=("$@")
  printf "%s\n" "${a[@]}"
}

paths=()

# Using while loop to handle file names properly
while IFS= read -r f; do
while IFS= read -r path; do
if [ -n "$path" ]; then
paths+=("$path")
fi
done < <(git log --follow --name-only --pretty=format: -- "$f")
done < <(find projects/util -type f)

git_repo_paths=""

for repo_path in `a_to_s "${paths[@]}" | sort | uniq`; do
git_repo_paths+=" --path $repo_path"
done

filter_repo_command="git-filter-repo $git_repo_paths --force --prune-degenerate always"

echo "$filter_repo_command"
=end
