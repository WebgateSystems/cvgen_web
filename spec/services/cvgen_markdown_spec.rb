# frozen_string_literal: true

require "rails_helper"

RSpec.describe CvgenMarkdown do
  it "gives every phone a label and number so Typst layouts can render" do
    raw = <<~MD
      ---
      name: Ada Lovelace
      phones:
        - "+44 7123 456789"
        - number: "+44 7987"
      links:
        - https://linkedin.com/in/ada
      ---

      # Summary
      Notes.
    MD

    result = described_class.normalize(raw)
    front = YAML.safe_load(result.split(/^---\s*$/, 3)[1])

    expect(front["phones"]).to eq(
      [
        { "label" => "Phone", "number" => "+44 7123 456789" },
        { "label" => "Phone", "number" => "+44 7987" }
      ]
    )
    expect(front["links"]).to eq(
      [ { "label" => "https://linkedin.com/in/ada", "url" => "https://linkedin.com/in/ada" } ]
    )
  end

  it "renders a formatted body preview without executing markup" do
    html = described_class.body_html("# Summary\n<script>x</script>\n- Skill\n  <!-- tags: ruby -->")
    expect(html).to include("<h1>Summary</h1>")
    expect(html).to include("&lt;script&gt;x&lt;/script&gt;")
    expect(html).not_to include("<script>x</script>")
    expect(html).to include("Skill")
    expect(html).to include("ruby")
  end

  it "splits front matter from the markdown body" do
    front, body = described_class.split_document("---\nname: Ada\n---\n\n# Summary\nHi\n")
    expect(front["name"]).to eq("Ada")
    expect(body).to include("# Summary")
  end
end
