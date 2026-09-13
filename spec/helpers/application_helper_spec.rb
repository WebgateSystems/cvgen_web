# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  it "groups theme options by kind" do
    system_theme = create(:theme, name: "System Blue")
    personal = create(:theme, :personal, name: "My Theme")
    html = helper.theme_options_for_select([ system_theme, personal ], system_theme.id)

    expect(html).to include("System Blue")
    expect(html).to include("My Theme")
    expect(html).to include("selected")
    expect(html).to include(system_theme.slug)
  end
end
