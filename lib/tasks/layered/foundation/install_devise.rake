namespace :layered do
  namespace :foundation do
    desc "Install Devise for authentication (auto-detected by layered-ui-rails): add the gem, run the install and model generators, migrate, and optionally require sign-in app-wide. Usage: rake \"layered:foundation:install_devise[User]\" (set NON_INTERACTIVE=1 for non-interactive runs)."
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
    puts "layered-ui-rails auto-detects Devise: styled auth views, header login/register"
    puts "buttons, and sidebar user info light up with no extra configuration."
    abort "Aborted." unless prompt_yes.call("Proceed? (y/yes or n/no): ")

    root = Pathname.new(Dir.pwd)
    # with_unbundled_env: subprocesses must not inherit this process's Bundler
    # context (RUBYOPT=-r bundler/setup etc.), or native extension builds like
    # bcrypt's extconf.rb fail with GemNotFound against the mid-update Gemfile.
    run = ->(*cmd) {
      puts "  $ #{cmd.join(' ')}"
      Bundler.with_unbundled_env { system(*cmd, chdir: root.to_s) } || abort("Aborted: `#{cmd.join(' ')}` failed. Fix the issue and re-run the task - completed steps are skipped or harmless to repeat.")
    }

    if root.join("Gemfile").read.match?(/^\s*gem ["']devise["']/)
      puts "Gemfile already includes devise - skipping `bundle add devise`."
    else
      run.call("bundle", "add", "devise")
    end

    # --skip leaves existing files untouched so a partially completed run can be retried.
    run.call("bin/rails", "generate", "devise:install", "--skip")
    run.call("bin/rails", "generate", "devise", model, "--skip")
    run.call("bin/rails", "db:migrate")

    if model != "User"
      initializer = root.join("config/initializers/layered_ui.rb")
      config_line = "Layered::Ui.current_user_method = :current_#{model_underscore}"
      if initializer.exist? && initializer.read.include?("current_user_method")
        puts "config/initializers/layered_ui.rb already sets current_user_method - left as is."
      else
        existing = initializer.exist? ? initializer.read : ""
        initializer.write("#{existing}#{config_line}\n")
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
    end
  end
end
