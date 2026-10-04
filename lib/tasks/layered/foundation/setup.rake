namespace :layered do
  namespace :foundation do
    desc "One-time setup for a freshly cloned foundation: rename the application and drop starter-only files. Usage: rake \"layered:foundation:setup[MyApp]\" (set NON_INTERACTIVE=1 for non-interactive runs). To reset git history afterwards, run layered:foundation:reset_git."
    task :setup, [ :name ] do |_, args|
    require "fileutils"

    current_module     = "LayeredFoundationRails"
    current_underscore = "layered_foundation_rails"
    current_dashed     = "layered-foundation-rails"

    name_re = /\A[A-Z][A-Za-z0-9]*\z/
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

    if args[:name].to_s.strip.empty?
      abort "Aborted: name argument is required when NON_INTERACTIVE is set." if auto_yes
      print "New application name (CamelCase, e.g. MyApp): "
      new_module = $stdin.gets.to_s.strip
      abort "Aborted: name cannot be blank." if new_module.empty?
    else
      new_module = args[:name].strip
    end
    unless new_module =~ name_re
      abort "Aborted: name must be CamelCase (letters/digits only, starting with an uppercase letter). Got: #{new_module.inspect}"
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
    abort "Aborted." unless prompt_yes.call("Proceed? (y/yes or n/no): ")

    root = Pathname.new(Dir.pwd)
    skip_dirs = %w[.git node_modules tmp log storage vendor/bundle .bundle public/assets]

    targets = []
    Dir.glob("**/*", File::FNM_DOTMATCH, base: root.to_s).each do |rel|
      path = root.join(rel)
      next unless path.file?
      next if skip_dirs.any? { |d| rel == d || rel.start_with?("#{d}/") }
      next if rel == "lib/tasks/layered/foundation/setup.rake"
      next if rel == "AGENTS.template.md"
      next if %w[NOTICE TRADEMARK.md CLA.md LICENSE template.rb].include?(rel)
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

    agents_template = root.join("AGENTS.template.md")
    agents_md = root.join("AGENTS.md")
    if agents_template.exist?
      FileUtils.mv(agents_template.to_s, agents_md.to_s)
      puts "Installed AGENTS.template.md as AGENTS.md."
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

    puts
    puts "Installing the layered-ui-rails agent skill from the gem..."
    if system("bin/rails", "generate", "layered:ui:install_agent_skill", "--force")
      puts "Installed .claude/skills/layered-ui-rails/ (version matched to the gem)."
    else
      puts "WARNING: could not install the layered-ui-rails agent skill automatically."
      puts "         Run 'bin/rails generate layered:ui:install_agent_skill' after bin/setup."
    end

    # The starter ships without credentials, so an existing credentials.yml.enc
    # belongs to this app (Layered commits one when it creates an app from the
    # template, and holds its key) - never replace it. Production won't boot
    # without a secret_key_base, so generate credentials when there are none.
    credentials = root.join("config/credentials.yml.enc")
    master_key  = root.join("config/master.key")
    missing_master_key = false
    puts
    if credentials.exist?
      if master_key.exist?
        puts "Keeping existing config/credentials.yml.enc and config/master.key."
      else
        missing_master_key = true
        puts "Keeping existing config/credentials.yml.enc, but config/master.key is missing."
        puts "  Get this app's master key (for apps created in Layered, it's on the app's GitHub"
        puts "  integration page) and save it as config/master.key. It's gitignored - don't commit it."
      end
    else
      puts "Generating credentials..."
      key_existed = master_key.exist?
      unless system({ "EDITOR" => "true", "RAILS_MASTER_KEY" => nil }, "bin/rails", "credentials:edit", out: File::NULL) &&
             credentials.exist? && master_key.exist?
        abort "Aborted: could not generate credentials. Run 'EDITOR=true bin/rails credentials:edit', " \
              "then delete lib/tasks/layered/foundation/setup.rake and the starter files by hand."
      end
      if key_existed
        puts "Created config/credentials.yml.enc, encrypted with the existing config/master.key."
      else
        puts "Created config/credentials.yml.enc and config/master.key (gitignored - keep it safe)."
      end
    end

    %w[NOTICE TRADEMARK.md CLA.md LICENSE template.rb].each do |filename|
      file = root.join(filename)
      if file.exist?
        File.unlink(file)
        puts "Removed #{filename}."
      end
    end

    task_file = root.join("lib/tasks/layered/foundation/setup.rake")
    if task_file.exist?
      File.unlink(task_file)
      puts "Removed lib/tasks/layered/foundation/setup.rake (no longer needed)."
    end

    puts
    puts "IMPORTANT (AI agents): AGENTS.md / CLAUDE.md has just been replaced. The version"
    puts "loaded at the start of this session is now stale. Read the new AGENTS.md in full"
    puts "before doing any further work - it carries the real working rules for this app."
    puts
    puts "Rename complete. Recommended next steps:"
    puts "  - Review the diff (or fresh tree)"
    puts "  - Review the new AGENTS.md - check it fits this app and add your own custom rules"
    if missing_master_key
      puts "  - Save this app's master key as config/master.key (for apps created in Layered, it's on the app's GitHub integration page)"
    else
      puts "  - Back up config/master.key somewhere safe (e.g. a password manager); deploys need it"
    end
    puts "  - bin/setup"
    puts "  - bin/rails test"
    puts "  - Optionally install Devise authentication with: rake \"layered:foundation:install_devise[User]\""
    puts "  - Optionally reset git history with: rake \"layered:foundation:reset_git\""
    end
  end
end
