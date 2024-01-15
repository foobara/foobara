#!/usr/bin/env ruby

require "pry"
require "English"

class ExtractRepo
  class << self
    def run!(repo_url, paths)
      new(repo_url, paths).execute
    end
  end

  attr_accessor :repo_url, :paths, :file_paths

  def initialize(repo_url, paths)
    self.repo_url = repo_url
    self.paths = paths
  end

  def execute
    mk_extract_dir
    rm_old_repo

    clone_repo
    remove_origin
    remove_tags
    determine_paths
    determine_historic_paths
    filter_repo
    remove_replaces
  end

  def chdir(dir, &)
    Dir.chdir(File.expand_path(dir), &)
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
    chdir extract_dir do
      sh "git clone #{repo_url}"
    end
  end

  def remove_origin
    chdir repo_dir do
      sh "git remote rm origin"
    end
  end

  def remove_tags
    chdir repo_dir do
      sh "for i in `git tag`; do git tag -d $i; done"
    end
  end

  def remove_replaces
    chdir repo_dir do
      sh "git replace -l | xargs -n 1 git replace -d"
    end
  end

  def determine_paths
    chdir repo_dir do
      self.file_paths = []

      chdir repo_dir do
        paths.each do |path|
          unless File.exist?(path)
            raise "Path #{path} does not exist in repo #{repo_dir}"
          end

          if File.directory?(path)
            Dir.glob("#{path}/**/*").each do |file|
              file_paths << file if File.file?(file)
            end
          else
            file_paths << path
          end
        end
      end
    end

    normalize_file_paths
  end

  def determine_historic_paths
    chdir repo_dir do
      file_paths.dup.each do |file_path|
        historic_paths = sh "git log --follow --name-only --pretty=format: -- \"#{file_path}\""

        historic_paths.split("\n").each do |historic_path|
          file_paths << historic_path
        end
      end
    end

    normalize_file_paths
  end

  def normalize_file_paths
    file_paths.sort!
    file_paths.uniq!
    file_paths.reject!(&:empty?)
  end

  def filter_repo
    chdir repo_dir do
      path_args = file_paths.map { |path| "--path #{path}" }.join(" ")
      sh "git-filter-repo #{path_args} --force --prune-degenerate always"
    end
  end

  def sh(cmd, dry_run: false)
    puts cmd

    return if dry_run

    result = `#{cmd}`

    unless $CHILD_STATUS.success?
      raise "Command #{cmd} failed with status #{$CHILD_STATUS.exitstatus}: #{result}"
    end

    result
  end
end

repo_url, *paths = ARGV
ExtractRepo.run!(repo_url, paths)

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

# ./extract_repo.rb git@github.com:foobara/foobara.git git-filter-repo spec/foobara/truncated_inspect/ spec/foobara/common/util_spec.rb projects/util/

# spec/foobara/truncated_inspect/
# spec/foobara/common/util_spec.rb
# projects/util/
