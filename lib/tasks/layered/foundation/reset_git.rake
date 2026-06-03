namespace :layered do
  namespace :foundation do
    desc "Remove the starter's git history: delete the .git directory and optionally re-initialise a fresh repository with an initial commit. Usage: rake \"layered:foundation:reset_git\" (set NON_INTERACTIVE=1 for non-interactive runs)."
    task :reset_git do
    require "fileutils"

    auto_yes = %w[y yes true 1].include?(ENV["NON_INTERACTIVE"].to_s.strip.downcase)
    prompt_yes = ->(question) {
      if auto_yes
        puts "#{question} [NON_INTERACTIVE: yes]"
        true
      else
        print question
        $stdin.gets.to_s.strip.downcase.start_with?("y")
      end
    }

    root = Pathname.new(Dir.pwd)

    git_dir = root.join(".git")
    git_removed = false
    if git_dir.exist?
      puts
      puts "WARNING: removing the .git directory will erase all version-control history,"
      puts "         remotes, branches, and stashes for this working copy. This cannot be undone."
      if prompt_yes.call("Remove .git directory? (y/yes or n/no): ")
        FileUtils.rm_rf(git_dir)
        git_removed = true
        puts "Removed .git directory."
      else
        puts "Kept .git directory."
      end
    else
      puts "No .git directory found - nothing to remove."
    end

    if git_removed
      # Remove this task file before re-initialising so a fresh repo's initial
      # commit never includes it (otherwise the self-deletion lands uncommitted).
      # Only do this once the user has committed to resetting git - if they kept
      # their .git, leave the task in place so it can be run again.
      task_file = root.join("lib/tasks/layered/foundation/reset_git.rake")
      if task_file.exist?
        File.unlink(task_file)
        puts "Removed lib/tasks/layered/foundation/reset_git.rake (no longer needed)."
      end

      if prompt_yes.call("Initialize a new git repository here? (y/yes or n/no): ")
        if system("git", "init", "-b", "main", chdir: root.to_s)
          if prompt_yes.call("Make an initial commit? (y/yes or n/no): ")
            if system("git", "add", "-A", chdir: root.to_s) &&
               system("git", "commit", "-m", "Initial commit", chdir: root.to_s)
              puts "Created initial commit."
            else
              puts "Failed to create initial commit. You can run `git add -A && git commit` manually."
            end
          else
            puts "Skipped initial commit."
          end
        else
          puts "Failed to run `git init`. You can run it manually."
        end
      else
        puts "Skipped `git init`. Run it manually when you're ready."
      end
    end
    end
  end
end
