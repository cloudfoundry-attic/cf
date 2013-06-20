require 'spec_helper'


module CF::App
  class PushInteractionClass
    include PushInteractions
    def ask(question, options); end
  end

  describe PushInteractionClass do
    let(:domains) { [build(:domain), build(:domain)]}
    let(:app){ build(:app, :space => build(:space, :domains => domains)) }

    describe "#ask_domain" do
      it "uses all space domains as choices with optional none" do
        subject.should_receive(:ask).with("Domain", anything) do |_, options|
          expect(options[:choices]).to eq(domains + ["none"])
        end

        subject.ask_domain(app)
      end

      it "has always a default value" do
        subject.should_receive(:ask).with("Domain", anything) do |_, options|
          expect(options[:default]).to eq domains.first
        end

        subject.ask_domain(app)
      end
    end
  end
end
