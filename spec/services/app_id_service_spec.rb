# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppIdService do
  describe ".version" do
    let(:revision_file) { Rails.root.join("REVISION") }

    before do
      described_class.instance_variable_set(:@version, nil)
    end

    after do
      described_class.instance_variable_set(:@version, nil)
      File.delete(revision_file) if File.exist?(revision_file)
    end

    context "when Capistrano REVISION is present" do
      let(:hash) { SecureRandom.hex }

      before { File.write(revision_file, "#{hash}\n") }

      it "returns the first 8 characters of the file" do
        expect(described_class.version).to eq(hash.first(8))
      end
    end

    context "when REVISION is missing" do
      before { File.delete(revision_file) if File.exist?(revision_file) }

      it "returns the git short hash" do
        expect(described_class.version).to match(/\A[a-f0-9]{8}\z/)
      end
    end
  end
end
