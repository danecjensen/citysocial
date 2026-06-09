class ApplicationController < ActionController::Base
  # Host-level concerns only: session, current_user resolution, the shell.
  # Module-specific controllers inherit from PlatformCore::BaseController.
end
