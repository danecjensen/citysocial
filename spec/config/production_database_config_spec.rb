require "rails_helper"

RSpec.describe "Production database configuration" do
  subject(:configuration) do
    ActiveRecord::Base.configurations.configs_for(env_name: "production", name: "primary").configuration_hash
  end

  it "keeps established database connections warm" do
    expect(configuration).to include(
      idle_timeout: 0,
      keepalives: 1,
      keepalives_idle: 60,
      keepalives_interval: 10,
      keepalives_count: 3
    )
  end
end
