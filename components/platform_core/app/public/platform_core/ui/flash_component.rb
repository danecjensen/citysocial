module PlatformCore
  module Ui
    class FlashComponent < ViewComponent::Base
      STYLES = {
        "notice" => "bg-success-soft text-success border-success/30",
        "alert" => "bg-warning-soft text-warning border-warning/30",
        "error" => "bg-danger-soft text-danger border-danger/30"
      }.freeze

      def initialize(type:, message:)
        @style = STYLES.fetch(type.to_s, STYLES["notice"])
        @message = message
      end

      erb_template <<~ERB
        <div class="rounded-md border px-4 py-3 text-sm font-bold <%= @style %>" role="status">
          <%= @message %>
        </div>
      ERB
    end
  end
end
