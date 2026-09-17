# frozen_string_literal: true

require "rails_helper"

RSpec.describe CvAnalysis do
  let(:json) do
    {
      "person_name" => "Ada Lovelace",
      "headline" => "Mathematician",
      "summary" => "Notes on the Analytical Engine.",
      "skills" => [ "Mathematics" ],
      "languages" => [ { "name" => "English", "level" => "C1" } ],
      "experience" => [],
      "education" => [],
      "strengths" => [],
      "gaps" => []
    }.to_json
  end

  before do
    client = instance_double(ChatGpt, call: json)
    allow(ChatGpt).to receive(:new).and_return(client)
  end

  it "sends pasted text to ChatGPT and returns normalized analysis" do
    result = described_class.new(text: "Ada Lovelace, mathematician.").call

    expect(result["person_name"]).to eq("Ada Lovelace")
    expect(result["skills"]).to eq([ "Mathematics" ])
    expect(ChatGpt).to have_received(:new).with(
      hash_including(json: true, prompt: a_string_including("Ada Lovelace, mathematician."))
    )
  end

  it "includes previous analysis when enriching" do
    described_class.new(
      text: "Also speaks French.",
      previous: { "person_name" => "Ada", "skills" => [ "Mathematics" ] }
    ).call

    expect(ChatGpt).to have_received(:new).with(
      hash_including(prompt: a_string_including("Previous analysis JSON"))
    )
  end

  it "raises when there is nothing to analyze" do
    expect { described_class.new(text: "  ").call }.to raise_error(CvAnalysis::EmptyInput)
  end

  it "raises when ChatGPT returns invalid JSON" do
    allow(ChatGpt).to receive(:new).and_return(instance_double(ChatGpt, call: "nope"))
    expect { described_class.new(text: "Ada").call }.to raise_error(CvAnalysis::InvalidJson)
  end

  it "sends extracted PDF text and does not attach the file" do
    page = instance_double(PDF::Reader::Page, text: "Ivan Maliuk")
    allow(PDF::Reader).to receive(:new).and_return(instance_double(PDF::Reader, pages: [ page ]))

    io = StringIO.new("%PDF-1.4")
    io.define_singleton_method(:original_filename) { "cv.pdf" }
    io.define_singleton_method(:size) { 8 }

    described_class.new(uploads: [ io ]).call

    expect(ChatGpt).to have_received(:new).with(
      hash_including(prompt: a_string_including("Ivan Maliuk"), files: [])
    )
  end

  it "raises when a PDF has no extractable text" do
    io = StringIO.new("%PDF-1.4")
    io.define_singleton_method(:original_filename) { "scan.pdf" }
    io.define_singleton_method(:size) { 8 }

    expect { described_class.new(uploads: [ io ]).call }.to raise_error(CvAnalysis::UnreadableFile)
    expect(ChatGpt).not_to have_received(:new)
  end
end
