# Rails application template for spinning up a new app with layered-ui-rails
# pre-configured.
#
# Usage:
#   rails new myapp --css tailwind -m path/to/template.rb
#   # or, once hosted:
#   rails new myapp --css tailwind -m https://raw.githubusercontent.com/<org>/<repo>/main/template.rb
#
# Requires: Rails 8.1+, --css tailwind (so tailwindcss-rails is wired up).

unless options[:css] == "tailwind"
  say "This template expects --css tailwind. Re-run with: rails new <app> --css tailwind -m <template>", :red
  exit 1
end

gem "layered-ui-rails"

after_bundle do
  generate "layered:ui:install"

  remove_file "app/views/layouts/application.html.erb"
  create_file "app/views/layouts/application.html.erb", <<~ERB
    <%= render template: "layouts/layered_ui/application" %>
  ERB

  generate :controller, "Pages", "index", "--skip-routes", "--skip-helper", "--no-test-framework"

  route 'root "pages#index"'

  remove_file "app/views/pages/index.html.erb"
  create_file "app/views/pages/index.html.erb", <<~ERB
    <h1>Hello World</h1>

    <p class="mt-4">Welcome to your new Rails app.</p>

    <p class="mt-4">
      Continue to build with layered-ui components, install the agent skill and check out the docs:
      <a href="https://layered-ui-rails.layered.ai/" target="_blank" rel="noopener noreferrer">layered-ui-rails</a>.
    </p>

    <p class="mt-4">
      To add an AI chat assistant to your app, see:
      <a href="https://layered-assistant-rails.layered.ai/" target="_blank" rel="noopener noreferrer">layered-assistant-rails</a>.
    </p>
  ERB

  say "\nlayered-ui-rails is installed and wired up.", :green
  say "Next steps:", :green
  say "  cd #{app_name}", :green
  say "  bin/setup", :green
  say "  visit: http://localhost:3000", :green
end
