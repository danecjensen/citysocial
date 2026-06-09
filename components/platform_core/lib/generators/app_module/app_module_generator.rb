require "rails/generators"

module AppModule
  # Scaffolds a new app-module (a mountable engine) that conforms to the
  # conventions in CLAUDE.md: depends only on platform_core, mounts at /name,
  # talks to other modules via the event bus, exposes a public API in app/public.
  #
  #   bin/rails g app_module marketplace
  #
  # This is the deterministic tool the /new-app-module command invokes, so the
  # agent never hand-rolls boilerplate.
  class AppModuleGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    def create_directories
      %w[app/models app/controllers app/views app/public db/migrate].each do |dir|
        create_file "components/#{file_name}/#{dir}/.keep", ""
      end
    end

    def create_module_files
      template "gemspec.tt",            "components/#{file_name}/#{file_name}.gemspec"
      template "engine.tt",             "components/#{file_name}/lib/#{file_name}/engine.rb"
      template "root.tt",               "components/#{file_name}/lib/#{file_name}.rb"
      template "version.tt",            "components/#{file_name}/lib/#{file_name}/version.rb"
      template "events.tt",             "components/#{file_name}/lib/#{file_name}/events.rb"
      template "application_record.tt", "components/#{file_name}/app/models/#{file_name}/application_record.rb"
      template "routes.tt",             "components/#{file_name}/config/routes.rb"
      template "package.tt",            "components/#{file_name}/package.yml"
      template "claude.tt",             "components/#{file_name}/CLAUDE.md"
      template "readme.tt",             "components/#{file_name}/README.md"
    end

    def wire_into_host
      gem_line = %(gem "#{file_name}", path: "components/#{file_name}"\n)
      inject_into_file "Gemfile", gem_line, after: %r{gem "feed",\s+path: "components/feed"\n}

      mount_line = "  mount #{class_name}::Engine => \"/#{file_name}\"\n"
      inject_into_file "config/routes.rb", mount_line, after: "Rails.application.routes.draw do\n"
    end

    def done
      say "\nModule '#{file_name}' created and wired into Gemfile + routes. Next:", :green
      say "  bundle install && bin/rails db:migrate"
    end
  end
end
