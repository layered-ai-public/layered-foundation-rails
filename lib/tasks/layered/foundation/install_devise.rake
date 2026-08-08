namespace :layered do
  namespace :foundation do
    desc "Install Devise for authentication (auto-detected by layered-ui-rails): add the gem, run the install and model generators, apply the layered.ai security baseline, migrate, and optionally require sign-in app-wide. Usage: rake \"layered:foundation:install_devise[User]\" (set NON_INTERACTIVE=1 for non-interactive runs)."
    task :install_devise, [ :model ] do |_, args|
    require "fileutils"

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

    model = args[:model].to_s.strip
    if model.empty?
      if auto_yes
        model = "User"
        puts "Model name [NON_INTERACTIVE: User]"
      else
        print "Devise model name (CamelCase, default User): "
        model = $stdin.gets.to_s.strip
        model = "User" if model.empty?
      end
    end
    unless model =~ name_re
      abort "Aborted: model name must be CamelCase (letters/digits only, starting with an uppercase letter). Got: #{model.inspect}"
    end

    model_underscore = model
                         .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                         .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                         .downcase

    puts
    puts "About to install Devise:"
    puts "  - add the devise gem to the Gemfile"
    puts "  - run the devise:install generator"
    puts "  - generate a #{model} model with devise_for routes"
    puts "  - run pending migrations"
    puts
    puts "layered-ui-rails auto-detects Devise: styled auth views, header login/register"
    puts "buttons, and sidebar user info light up with no extra configuration."
    abort "Aborted." unless prompt_yes.call("Proceed? (y/yes or n/no): ")

    # Both extras are asked for up front so the run doesn't stop for input midway
    # through generators and migrations.
    puts
    puts "Security baseline (written into config/initializers/devise.rb and the model):"
    puts "  - 12-character minimum password"
    puts "  - account lockout after 10 failed attempts, auto-unlock after 1 hour"
    puts "  - 30-minute idle session timeout"
    puts "  - paranoid mode (no user-enumeration via auth error messages)"
    puts "Declining leaves Devise's own defaults in place, including a 6-character"
    puts "minimum password and no lockout."
    baseline = prompt_yes.call("Apply the security baseline (recommended)? (y/yes or n/no): ")

    puts
    puts "Breached-password checking rejects passwords that appear in known breaches,"
    puts "via the devise-pwned_password gem. A length minimum on its own still accepts"
    puts "\"aaaaaaaaaaaa\", so this is what makes it mean something. Note it checks the"
    puts "Have I Been Pwned API rather than a local list, so sign-up and password"
    puts "changes make an outbound HTTPS call (k-anonymity: only the first 5 characters"
    puts "of the password's SHA-1 hash ever leave the app)."
    denylist = prompt_yes.call("Reject breached passwords (recommended)? (y/yes or n/no): ")

    root = Pathname.new(Dir.pwd)
    # with_unbundled_env: subprocesses must not inherit this process's Bundler
    # context (RUBYOPT=-r bundler/setup etc.), or native extension builds like
    # bcrypt's extconf.rb fail with GemNotFound against the mid-update Gemfile.
    run = ->(*cmd) {
      puts "  $ #{cmd.join(' ')}"
      Bundler.with_unbundled_env { system(*cmd, chdir: root.to_s) } || abort("Aborted: `#{cmd.join(' ')}` failed. Fix the issue and re-run the task - completed steps are skipped or harmless to repeat.")
    }
    # Same, but a failure is reported and tolerated rather than aborting the run.
    # Used for the optional extras so they can't strand a half-installed Devise.
    run_soft = ->(*cmd) {
      puts "  $ #{cmd.join(' ')}"
      Bundler.with_unbundled_env { system(*cmd, chdir: root.to_s) }
    }
    if root.join("Gemfile").read.match?(/^\s*gem ["']devise["']/)
      puts "Gemfile already includes devise - skipping `bundle add devise`."
    else
      run.call("bundle", "add", "devise")
    end

    # --skip leaves existing files untouched so a partially completed run can be retried.
    run.call("bin/rails", "generate", "devise:install", "--skip")
    run.call("bin/rails", "generate", "devise", model, "--skip")

    puts
    puts "Applying options..."

    # Devise modules the extras need. Collected from both prompts and written to
    # the model in one pass below, since the two options can be chosen separately.
    modules = []
    modules.concat(%w[lockable timeoutable]) if baseline

    # --- Optional: breached-password checking ----------------------------------
    if denylist
      if root.join("Gemfile").read.match?(/^\s*gem ["']devise-pwned_password["']/)
        puts "  - Gemfile already includes devise-pwned_password."
        modules << "pwned_password"
      elsif run_soft.call("bundle", "add", "devise-pwned_password")
        modules << "pwned_password"
      else
        puts "  ! `bundle add devise-pwned_password` failed - continuing without it."
      end
    end

    # --- Migration: enable the Lockable columns -------------------------------
    # The generated migration ships them commented out. They have to be
    # uncommented before db:migrate, so this runs ahead of the migrate step.
    # All three columns (not just the two :time unlocking needs) are enabled so
    # switching unlock_strategy to :email later needs no extra migration.
    migration = baseline ? Dir.glob(root.join("db/migrate/*_devise_create_*.rb").to_s).max : nil
    if !baseline
      puts "  - Skipped the Lockable columns (baseline declined)."
    elsif migration.nil?
      puts "  ! No devise_create migration found - skipping Lockable columns."
    else
      path = Pathname.new(migration)
      content = path.read
      original = content.dup
      %w[failed_attempts unlock_token locked_at].each do |column|
        content = content.sub(/^([ \t]*)#[ \t]*(t\.\w+[ \t]+:#{column}\b.*)$/i) { "#{$1}#{$2}" }
      end
      content = content.sub(/^([ \t]*)#[ \t]*(add_index[ \t]+.*:unlock_token\b.*)$/) { "#{$1}#{$2}" }
      # Some Devise versions ship this line as `t.Integer`, which is not a real
      # column type and raises NoMethodError once uncommented.
      content = content.gsub(/^([ \t]*)t\.Integer\b/) { "#{$1}t.integer" }
      if content == original
        puts "  - #{path.basename}: Lockable columns already enabled (or not present)."
      else
        path.write(content)
        puts "  - #{path.basename}: enabled the Lockable columns."
      end
    end

    # --- Model: add the modules the chosen options need -------------------------
    model_file = root.join("app/models/#{model_underscore}.rb")
    wanted = modules.map { |mod| ":#{mod}" }.join(", ")
    if modules.empty?
      puts "  - No model changes needed."
    elsif !model_file.exist?
      puts "  ! #{model_file.relative_path_from(root)} not found - add `#{wanted}` to the devise call yourself."
    else
      content = model_file.read
      # The generated `devise` call wraps across lines; consume continuation
      # lines (each ending in a comma) so modules are appended to the whole call.
      statement = content[/^[ \t]*devise[ \t]+(?:[^\n]*,[ \t]*\n)*[^\n]*$/]
      if statement.nil?
        puts "  ! Couldn't find the devise call in #{model_file.relative_path_from(root)} - add `#{wanted}` yourself."
      else
        added = modules.reject { |mod| statement.match?(/:#{mod}\b/) }
        if added.empty?
          puts "  - #{model_file.relative_path_from(root)}: modules already present."
        else
          model_file.write(content.sub(statement, "#{statement}, #{added.map { |mod| ":#{mod}" }.join(', ')}"))
          puts "  - #{model_file.relative_path_from(root)}: added #{added.map { |mod| ":#{mod}" }.join(', ')}."
        end
      end
    end

    run.call("bin/rails", "db:migrate")

    # --- Initializer: the baseline itself --------------------------------------
    # Written as config, not as advice in a README, so every generated app gets
    # it identically whether or not a human or an agent reads the docs.
    initializer = root.join("config/initializers/devise.rb")
    if !baseline
      puts "  - Left config/initializers/devise.rb at Devise's defaults (baseline declined)."
    elsif !initializer.exist?
      puts "  ! config/initializers/devise.rb not found - skipping the baseline settings."
    else
      content = initializer.read
      missing = []
      settings = [
        [ "password_length",  "12..128",             "12-char minimum" ],
        [ "paranoid",         "true",                "identical responses whether or not an account exists" ],
        [ "timeout_in",       "30.minutes",          "idle session timeout (needs :timeoutable on the model)" ],
        [ "lock_strategy",    ":failed_attempts",    "brute-force protection (needs :lockable on the model)" ],
        [ "maximum_attempts", "10",                  "lock after 10 failed attempts" ],
        [ "unlock_strategy",  ":time",               "auto-unlock; switch to :email once a mailer is configured" ],
        [ "unlock_in",        "1.hour",              "lockout duration" ]
      ]
      settings.each do |key, value, note|
        # Matches the setting whether the generated initializer ships it
        # commented out (most of these) or active (password_length).
        re = /^([ \t]*)#?[ \t]*config\.#{Regexp.escape(key)}[ \t]*=.*$/
        if content.match?(re)
          content = content.sub(re) { "#{$1}config.#{key} = #{value}  # layered.ai baseline: #{note}" }
        else
          missing << "config.#{key} = #{value}"
        end
      end
      initializer.write(content)
      puts "  - config/initializers/devise.rb: applied #{settings.length - missing.length}/#{settings.length} baseline settings."
      unless missing.empty?
        puts "  ! Couldn't find these settings in the initializer - add them by hand:"
        missing.each { |line| puts "      #{line}" }
      end
    end

    if model != "User"
      layered_initializer = root.join("config/initializers/layered_ui.rb")
      config_line = "Layered::Ui.current_user_method = :current_#{model_underscore}"
      if layered_initializer.exist? && layered_initializer.read.include?("current_user_method")
        puts "config/initializers/layered_ui.rb already sets current_user_method - left as is."
      else
        existing = layered_initializer.exist? ? layered_initializer.read : ""
        layered_initializer.write("#{existing}#{config_line}\n")
        puts "Pointed Layered::Ui.current_user_method at :current_#{model_underscore}."
      end
    end

    app_controller = root.join("app/controllers/application_controller.rb")
    auth_line = "before_action :authenticate_#{model_underscore}!, unless: :devise_controller?"
    if app_controller.read.include?("authenticate_#{model_underscore}!")
      puts "ApplicationController already requires authentication - left as is."
    elsif prompt_yes.call("Require sign-in app-wide (before_action :authenticate_#{model_underscore}! in ApplicationController)? (y/yes or n/no): ")
      content = app_controller.read
      updated = content.sub(/^(class ApplicationController < ActionController::Base\n)/) { "#{$1}  #{auth_line}\n\n" }
      if updated == content
        puts "Couldn't find the ApplicationController class line - add this yourself:"
        puts "  #{auth_line}"
      else
        app_controller.write(updated)
        puts "Added app-wide authentication to ApplicationController."
      end
    else
      puts "Skipped app-wide authentication. Add `#{auth_line}` to controllers that need it."
    end

    task_file = root.join("lib/tasks/layered/foundation/install_devise.rake")
    if task_file.exist?
      File.unlink(task_file)
      puts "Removed lib/tasks/layered/foundation/install_devise.rake (no longer needed)."
    end

    puts
    puts "Devise installed. Recommended next steps:"
    puts "  - Review the diff, then run bin/rails test"
    puts "  - Start the app (bin/dev) and visit the sign-up page (see: bin/rails routes -g #{model_underscore})"
    puts "  - Adjust config/initializers/devise.rb (mailer sender, modules) to taste"
    puts
    if baseline
      puts "The security baseline is config, not advice - it stays in force until someone"
      puts "edits it."
    else
      puts "The security baseline was declined, so Devise's own defaults apply - notably a"
      puts "6-character minimum password and no account lockout. To apply it later, set the"
      puts "values in config/initializers/devise.rb by hand; :lockable also needs the"
      puts "failed_attempts/locked_at columns, which now takes a new migration."
    end
    end
  end
end
