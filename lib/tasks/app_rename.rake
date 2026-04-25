namespace :app do
  desc "Rename this application (module/class, gem-style, and dasherized names) across the codebase."
  task :rename do
    require "fileutils"

    current_module     = "LayeredFoundationRails"
    current_underscore = "layered_foundation_rails"
    current_dashed     = "layered-foundation-rails"

    print "New application name (CamelCase, e.g. MyApp): "
    new_module = $stdin.gets.to_s.strip
    abort "Aborted: name cannot be blank." if new_module.empty?
    unless new_module =~ /\A[A-Z][A-Za-z0-9]*\z/
      abort "Aborted: name must be CamelCase (letters/digits only, starting with an uppercase letter)."
    end

    new_underscore = new_module
                       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                       .downcase
    new_dashed = new_underscore.tr("_", "-")

    puts
    puts "About to rename:"
    puts "  #{current_module}      -> #{new_module}"
    puts "  #{current_underscore}  -> #{new_underscore}"
    puts "  #{current_dashed}      -> #{new_dashed}"
    print "Proceed? (yes/no): "
    abort "Aborted." unless $stdin.gets.to_s.strip.downcase.start_with?("y")

    root = Pathname.new(Dir.pwd)
    skip_dirs = %w[.git node_modules tmp log storage vendor/bundle .bundle public/assets]

    targets = []
    Dir.glob("**/*", File::FNM_DOTMATCH, base: root.to_s).each do |rel|
      path = root.join(rel)
      next unless path.file?
      next if skip_dirs.any? { |d| rel == d || rel.start_with?("#{d}/") }
      next if rel == "lib/tasks/app_rename.rake"
      next if %w[NOTICE TRADEMARK.md CLA.md LICENSE].include?(rel)
      targets << path
    end

    changed = 0
    targets.each do |path|
      begin
        content = path.read
      rescue ArgumentError, Errno::EACCES
        next
      end
      next unless content.valid_encoding?
      original = content.dup
      content = content.gsub(current_module, new_module)
                       .gsub(current_underscore, new_underscore)
                       .gsub(current_dashed, new_dashed)
      if content != original
        path.write(content)
        changed += 1
        puts "  updated #{path.relative_path_from(root)}"
      end
    end
    puts "Updated #{changed} file(s)."

    agents_md = root.join("AGENTS.md")
    if agents_md.exist?
      agents_md.write(<<~MD)
        # AGENTS.md

        This file is a guide for AI coding agents working in this repository. Replace this scaffold with project-specific guidance as the codebase grows.

        Suggested sections to fill in:

        - **Project overview** — one paragraph on what this app does and who it's for.
        - **Commands** — how to run the dev server, tests, linters, and any custom rake tasks.
        - **Architecture** — the key stack choices, where domain logic lives, and any conventions an agent should follow (naming, file layout, testing style).
        - **Domain glossary** — terms specific to this product that an agent wouldn't infer from the code alone.
        - **Do / don't** — guardrails: things to always do (e.g. "run `bin/rubocop -a` before committing") and things to avoid (e.g. "don't add new gems without discussion").
        - **External systems** — pointers to issue trackers, dashboards, runbooks, or docs that live outside this repo.

        Keep it concise — agents read this on every task, so prefer high-signal notes over exhaustive documentation.
      MD
      puts "Reset AGENTS.md to a fresh scaffold."
    end

    readme = root.join("README.md")
    if readme.exist?
      readme.write(<<~MD)
        # #{new_module}

        TODO: describe this application.

        ## Getting Started

        ```bash
        bin/setup
        bin/dev
        ```
      MD
      puts "Reset README.md to a fresh scaffold."
    end

    %w[NOTICE TRADEMARK.md CLA.md LICENSE].each do |filename|
      file = root.join(filename)
      if file.exist?
        File.unlink(file)
        puts "Removed #{filename}."
      end
    end

    git_dir = root.join(".git")
    if git_dir.exist?
      puts
      puts "WARNING: removing the .git directory will erase all version-control history,"
      puts "         remotes, branches, and stashes for this working copy. This cannot be undone."
      print "Remove .git directory? (yes/no): "
      if $stdin.gets.to_s.strip.downcase.start_with?("y")
        FileUtils.rm_rf(git_dir)
        puts "Removed .git directory. Run `git init` to start a fresh repository."
      else
        puts "Kept .git directory."
      end
    end

    task_file = root.join("lib/tasks/app_rename.rake")
    if task_file.exist?
      File.unlink(task_file)
      puts "Removed lib/tasks/app_rename.rake (no longer needed)."
    end

    puts
    puts "Rename complete. Recommended next steps:"
    puts "  - Review the diff (or fresh tree)"
    puts "  - bin/setup"
    puts "  - bin/rails test"
  end
end
