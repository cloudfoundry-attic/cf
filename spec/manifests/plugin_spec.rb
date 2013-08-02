require "spec_helper"

describe ManifestsPlugin do
  let(:manifest) { {} }
  let(:manifest_file) { nil }
  let(:inputs_hash) { {} }
  let(:given_hash) { {} }
  let(:global_hash) { { :quiet => true } }
  let(:command) { nil }
  let(:inputs) { Mothership::Inputs.new(Mothership.commands[:push], nil, inputs_hash, given_hash, global_hash) }
  let(:plugin) { ManifestsPlugin.new(command, inputs) }

  let(:client) { build(:client) }

  before do
    plugin.stub(:manifest) { manifest }
    plugin.stub(:manifest_file) { manifest_file } if manifest_file
    plugin.stub(:client) { client }
  end

  describe ".use_manifest_for_app_input" do
    it "makes the app argument optional and wraps it in an around that gets the app from the manifest" do
      command = described_class.commands[:app]
      command.instance_variable_set(:@arguments, [{:name => :app, :type => :required, :value => nil}])

      expect(command.arguments).to eq [{:name => :app, :type => :required, :value => nil}]
      expect(command.around.size).to eq 1

      described_class.default_to_app_from_manifest :app, false

      expect(command.arguments).to eq [{:name => :app, :type => :optional, :value => nil}]
      expect(command.around.size).to eq 2
    end
  end

  describe "#wrap_with_optional_name" do
    let(:name_made_optional) { true }
    let(:fail_without_app) { true }
    let(:wrapped) { double(:wrapped).as_null_object }

    subject { plugin.send(:wrap_with_optional_name, name_made_optional, wrapped, inputs, fail_without_app) }

    context "when --all is given" do
      let(:inputs_hash) { { :all => true } }

      it "skips all manifest-related logic, and invokes the command" do
        wrapped.should_receive(:call)
        plugin.should_not_receive(:show_manifest_usage)
        subject
      end
    end

    context "when there is no manifest" do
      let(:manifest) { nil }

      context "and an app is given" do
        let(:given_hash) { { :app => "foo" } }

        it "passes through to the command" do
          wrapped.should_receive(:call)
          plugin.should_not_receive(:show_manifest_usage)
          subject
        end
      end

      context "and an app is NOT given" do
        let(:inputs_hash) { {} }

        context "and we made it optional" do
          it "fails manually" do
            plugin.should_receive(:no_apps)
            subject
          end

          context "when it is not supposed to fail" do
            let(:fail_without_app) { false }
            it "doesnt fail" do
              plugin.should_not_receive(:no_apps)
              subject
            end
          end
        end

        context "and we did NOT make it optional" do
          let(:name_made_optional) { false }

          it "passes through to the command" do
            wrapped.should_receive(:call)
            plugin.should_not_receive(:show_manifest_usage)
            subject
          end
        end
      end
    end

    context "when there is a manifest" do
      let(:manifest_file) { "/abc/manifest.yml" }

      before do
        plugin.stub(:show_manifest_usage)
      end

      context "when no apps are given" do
        context "and the user's working directory matches a particular app in the manifest" do
          let(:manifest) { { :applications => [{ :name => "foo", :path => "/abc/foo" }] } }

          it "calls the command for only that app" do
            wrapped.should_receive(:call).with(anything) do |inputs|
              expect(inputs.given[:app]).to eq "foo"
            end

            Dir.stub(:pwd) { "/abc/foo" }

            subject
          end
        end

        context "and the user's working directory isn't in the manifest" do
          let(:manifest) { { :applications => [{ :name => "foo" }, { :name => "bar" }] } }

          it "calls the command for all apps in the manifest" do
            uncalled_apps = ["foo", "bar"]
            wrapped.should_receive(:call).with(anything).twice do |inputs|
              uncalled_apps.delete inputs.given[:app]
            end

            subject

            expect(uncalled_apps).to be_empty
          end
        end
      end

      context "when any of the given apps are not in the manifest" do
        let(:manifest) { { :applications => [{ :name => "a" }, { :name => "b" }] } }

        context "and --apps is given" do
          let(:given_hash) { { :apps => ["x", "a"] } }

          it "passes through to the original command" do
            plugin.should_receive(:show_manifest_usage)

            uncalled_apps = ["a", "x"]
            wrapped.should_receive(:call).with(anything).twice do |inputs|
              uncalled_apps.delete inputs.given[:app]
            end

            subject

            expect(uncalled_apps).to be_empty
            subject
          end
        end
      end

      context "when none of the given apps are in the manifest" do
        let(:manifest) { { :applications => [{ :name => "a" }, { :name => "b" }] } }

        context "and --apps is given" do
          let(:given_hash) { { :apps => ["x", "y"] } }

          it "passes through to the original command" do
            wrapped.should_receive(:call)
            plugin.should_not_receive(:show_manifest_usage)
            subject
          end
        end
      end

      context "when an app name that's in the manifest is given" do
        let(:manifest) { { :applications => [{ :name => "foo" }] } }
        let(:given_hash) { { :app => "foo" } }

        it "calls the command with that app" do
          wrapped.should_receive(:call).with(anything) do |inputs|
            expect(inputs.given[:app]).to eq "foo"
          end

          subject
        end
      end

      context "when a path to an app that's in the manifest is given" do
        let(:manifest) { { :applications => [{ :name => "foo", :path => "/abc/foo" }] } }
        let(:given_hash) { { :app => "/abc/foo" } }

        it "calls the command with that app" do
          wrapped.should_receive(:call).with(anything) do |inputs|
            expect(inputs.given[:app]).to eq "foo"
          end

          subject
        end
      end
    end
  end

  describe "#wrap_push" do
    let(:wrapped) { double(:wrapped).as_null_object }
    let(:command) { Mothership.commands[:push] }

    subject { plugin.send(:wrap_push, wrapped, inputs) }

    before do
      plugin.stub(:show_manifest_usage)
    end

    context "with a manifest" do
      let(:manifest_file) { "/abc/manifest.yml" }

      let(:manifest) do
        { :applications => [
          { :name => "a",
            :path => "/abc/a",
            :instances => "200",
            :memory => "128M"
          }
        ]
        }
      end

      # cf push foo
      context "and a name is given" do
        context "and the name is present in the manifest" do
          let(:given_hash) { { :name => "a" } }
          let(:app) { build :app, :name => "a" }

          before do
            client.stub(:apps => [app])
            client.stub(:app_by_name).with("a").and_return(app)
          end

          context "and the app exists" do

            context "and --reset was given" do
              let(:inputs_hash) { { :reset => true } }
              let(:given_hash) { { :name => "a", :instances => "100" } }

              it "rebases their inputs on the manifest's values" do
                wrapped.should_receive(:call).with(anything) do |inputs|
                  expect(inputs.given).to eq(
                    :name => "a", :path => "/abc/a", :instances => "100", :memory => "128M")
                end

                subject
              end
            end
          end

          context "and the app does NOT exist" do
            let(:app) { nil }

            it "pushes a new app with the inputs from the manifest" do
              wrapped.should_receive(:call).with(anything) do |inputs|
                expect(inputs.given).to eq(
                  :name => "a", :path => "/abc/a", :instances => "200", :memory => "128M")
              end

              subject
            end
          end
        end

        context "and the name is NOT present in the manifest" do
          let(:given_hash) { { :name => "x" } }

          it "fails, saying that name was not found in the manifest" do
            expect { subject }.to raise_error(CF::UserError, /Could not find .+ in the manifest./)
          end
        end
      end

      # cf push ./abc
      context "and a path is given" do
        context "and there are apps matching that path in the manifest" do
          before do
            client.stub(:apps => [build(:app), build(:app)])
            client.stub(:app_by_name)
          end

          let(:manifest) do
            { :applications => [
              { :name => "a",
                :path => "/abc/a",
                :instances => "200",
                :memory => "128M"
              },
              { :name => "b",
                :path => "/abc/a",
                :instances => "200",
                :memory => "128M"
              }
            ]
            }
          end

          let(:given_hash) { { :name => "/abc/a" } }

          it "pushes the found apps" do
            pushed_apps = []
            wrapped.should_receive(:call).with(anything).twice do |inputs|
              pushed_apps << inputs[:name]
            end

            subject

            expect(pushed_apps).to eq(["a", "b"])
          end
        end

        context "and there are NOT apps matching that path in the manifest" do
          let(:given_hash) { { :name => "/abc/x" } }

          it "fails, saying that the path was not found in the manifest" do
            expect { subject }.to raise_error(CF::UserError, /Path .+ is not present in manifest/)
          end
        end
      end

      context "and --path is specified too" do
        let(:given_hash) { { :path => "/somewhere/else" } }

        it "warns the user that --path will be ignored" do
          plugin.stub(:line)
          plugin.stub(:push_with_manifest)

          subject

          expect(plugin).to have_received(:line).with("--path is ignored when using a manifest. Please specify the path in the manifest.")
        end
      end
    end

    context "without a manifest" do
      let(:app) { double(:app).as_null_object }
      let(:manifest) { nil }

      it "asks to save the manifest when uploading the application" do
        should_ask("Save configuration?", :default => false)
        wrapped.stub(:call) { plugin.filter(:push_app, app) }
        subject
      end
    end
  end

  describe "#push_input_for" do
    context "with an existing app" do
      before do
        plugin.stub(:from_manifest) { "PATH" }
        app.changes.clear
        client.stub(:apps => [app])
      end

      let(:manifest_memory) { "256M" }
      let(:app) { build(:app, :name => "a", :memory => 256) }
      let(:manifest) { { :name => "a", :memory => manifest_memory } }

      subject { plugin.send(:push_input_for, manifest, inputs) }

      context "with --reset" do
        let(:inputs_hash) { { :reset => true } }

        context "with changes" do
          let(:manifest_memory) { "128M" }

          it "applies the changes" do
            subject[:memory].should == "128M"
          end

          it "does not ask to set --reset" do
            plugin.should_not_receive(:warn_reset_changes)
            subject
          end
        end

        context "without changes" do
          it "does not ask to set --reset" do
            plugin.should_not_receive(:warn_reset_changes)
            subject
          end
        end
      end

      context "without --reset" do
        let(:inputs_hash) { {} }

        context "with changes" do
          let(:manifest_memory) { "128M" }

          it "asks user to provide --reset" do
            plugin.should_receive(:warn_reset_changes)
            subject
          end

          it "does not apply changes" do
            plugin.stub(:warn_reset_changes)
            subject[:memory].should == nil
          end
        end

        context "without changes" do
          it "does not ask to set --reset" do
            plugin.should_not_receive(:warn_reset_changes)
            subject
          end
        end
      end
    end
  end
end
