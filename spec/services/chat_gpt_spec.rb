# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatGpt do
  let(:prompt) { "Test prompt" }
  let(:fake_response_text) { "Parsed CV result" }
  let(:mock_client) { instance_double(OpenAI::Client) }
  let(:mock_completion) do
    double(choices: [ double(message: double(content: fake_response_text)) ])
  end

  before do
    allow(OpenAI::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive_message_chain(:chat, :completions, :create).and_return(mock_completion)
  end

  it "returns the OpenAI message content" do
    expect(described_class.new(prompt: prompt).call).to eq(fake_response_text)
  end

  it "loads a named prompt from config/prompts" do
    allow(ChatGpt::Prompt).to receive(:load).with("cv_analysis").and_call_original
    described_class.new(prompt_name: "cv_analysis").call
    expect(ChatGpt::Prompt).to have_received(:load).with("cv_analysis")
  end

  it "sends a user message with the prompt" do
    expect(mock_client).to receive_message_chain(:chat, :completions, :create).with(
      hash_including(
        model: "gpt-4o",
        messages: [ hash_including(role: "user", content: prompt) ],
        temperature: 0.2
      )
    )

    described_class.new(prompt: prompt).call
  end

  it "asks for a JSON object when json: true" do
    expect(mock_client).to receive_message_chain(:chat, :completions, :create).with(
      hash_including(response_format: { type: "json_object" })
    )

    described_class.new(prompt: prompt, json: true).call
  end

  it "raises without a prompt" do
    expect { described_class.new }.to raise_error(ArgumentError, /prompt/)
  end

  it "attaches a base64 image when an image file is given" do
    file = StringIO.new("\x89PNG\r\n\x1A\n")
    file.define_singleton_method(:original_filename) { "cv.png" }

    expect(mock_client).to receive_message_chain(:chat, :completions, :create).with(
      hash_including(
        messages: [ hash_including(content: array_including(hash_including(type: "image_url"))) ]
      )
    )

    described_class.new(prompt: prompt, file: file).call
  end

  it "attaches a PDF as a file part" do
    file = StringIO.new("%PDF-1.4 fake")
    file.define_singleton_method(:original_filename) { "cv.pdf" }

    expect(mock_client).to receive_message_chain(:chat, :completions, :create).with(
      hash_including(
        messages: [ hash_including(content: array_including(hash_including(type: "file"))) ]
      )
    )

    described_class.new(prompt: prompt, files: [ file ]).call
  end

  it "parses JSON even when wrapped in a markdown fence" do
    expect(described_class.parse_json("```json\n{\"person_name\":\"Ada\"}\n```")).to eq("person_name" => "Ada")
  end

  it "strips a markdown fence around a CV" do
    expect(described_class.parse_markdown("```markdown\n---\nname: Ada\n---\n```")).to eq("---\nname: Ada\n---")
  end

  it "raises when the JSON cannot be parsed" do
    expect { described_class.parse_json("not json") }.to raise_error(ArgumentError, /JSON/)
  end

  it "raises when the API key is missing" do
    allow(Settings).to receive(:chat_gpt_api_key).and_return("")

    expect { described_class.new(prompt: prompt) }.to raise_error(ArgumentError, /chat_gpt_api_key/)
  end
end
