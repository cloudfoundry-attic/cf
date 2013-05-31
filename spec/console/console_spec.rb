require "spec_helper"

describe CFConsole do
  before do
    @app = double("app")
    @console = CFConsole.new(nil, @app)
  end

  it "should return connection info for apps that have a console ip and port" do
    instance = double("instance")
    @app.should_receive(:instances) { [instance] }
    instance.should_receive(:console) { {:ip => "192.168.1.1", :port => 3344} }

    @console.get_connection_info(nil).should == {
      "hostname" => "192.168.1.1",
      "port" => 3344
    }
  end

  it "should raise error when no app instances found" do
    @app.should_receive(:instances) { [] }

    expect {
      @console.get_connection_info(nil)
    }.to raise_error("App has no running instances; try starting it.")
  end

  it "should raise error when app does not have console access" do
    instance = double("instance")
    @app.should_receive(:instances) { [instance] }
    instance.should_receive(:console) { nil }

    expect {
      @console.get_connection_info(nil)
    }.to raise_error("App does not have console access; try restarting it.")
  end

  describe "start_console" do
    before do
      @creds = {
        :path => %w(app cf-rails-console .consoleaccess),
        :yaml => "username: cfuser\npassword: testpw",
        :telnet => {"Name" => "cfuser", "Password" => "testpw"}
      }
    end

    context "when console credentials cannot be obtained" do
      it "should raise error" do
        @app.should_receive(:file).with(*@creds[:path]) { "username: cfuser" }

        expect {
          @console.start_console
        }.to raise_error("Unable to verify console credentials.")
      end
    end

    context "when console credentials can be obtained" do
      before do
        @app.should_receive(:file).with(*@creds[:path]) { @creds[:yaml] }
        @telnet = Object.new
        @console.should_receive(:telnet_client).and_return(@telnet)
      end

      it "should raise error if authentication fails" do
        @telnet.should_receive(:login).with(@creds[:telnet]) { "Login failed" }
        @telnet.should_receive(:close)

        expect { @console.start_console }.to raise_error("Login failed")
      end

      it "should retry authentication on timeout" do
        @telnet.should_receive(:login).with(@creds[:telnet]){ raise TimeoutError }
        @telnet.should_receive(:login).with(@creds[:telnet]) { "Switch to inspect mode\nirb():001:0> " }
        verify_console_exit("irb():001:0> ")

        @console.start_console
      end

      it "should retry authentication on EOF" do
        @console.should_receive(:telnet_client).and_return(@telnet)
        @telnet.should_receive(:login).with(@creds[:telnet]) { raise EOFError }
        @telnet.should_receive(:close)
        @telnet.should_receive(:login).with(@creds[:telnet]).and_return("irb():001:0> ")
        verify_console_exit("irb():001:0> ")

        @console.start_console
      end

      it "should operate console interactively" do
        @telnet.should_receive(:login).with(@creds[:telnet]).and_return("irb():001:0> ")
        Readline.should_receive(:readline).with("irb():001:0> ") { "puts 'hi'" }
        Readline::HISTORY.should_receive(:push).with("puts 'hi'")
        @telnet.should_receive(:cmd).with("puts 'hi'").and_return("nil" + "\n" + "irb():002:0> ")
        @console.should_receive(:puts).with("nil")
        verify_console_exit("irb():002:0> ")

        @console.start_console
      end

      it "should not crash if command times out" do
        @telnet.should_receive(:login).with(@creds[:telnet]).and_return("irb():001:0> ")
        Readline.should_receive(:readline).with("irb():001:0> ") { "puts 'hi'" }
        Readline::HISTORY.should_receive(:push).with("puts 'hi'")
        @telnet.should_receive(:cmd).with("puts 'hi'") { raise TimeoutError }
        @console.should_receive(:puts).with("Timed out sending command to server.")
        verify_console_exit("irb():001:0> ")

        @console.start_console
      end

      it "should raise error if an EOF is received" do
        @telnet.should_receive(:login).with(@creds[:telnet]).and_return("Switch to inspect mode\nirb():001:0> ")
        Readline.should_receive(:readline).with("irb():001:0> ") { "puts 'hi'" }
        Readline::HISTORY.should_receive(:push).with("puts 'hi'")
        @telnet.should_receive(:cmd).with("puts 'hi'") { raise EOFError }

        expect {
          @console.start_console
        }.to raise_error("The console connection has been terminated. Perhaps the app was stopped or deleted?")
      end

      it "should not keep blank lines in history" do
        @telnet.should_receive(:login).with(@creds[:telnet]).and_return("irb():001:0> ")
        Readline.should_receive(:readline).with("irb():001:0> ") { "" }
        Readline::HISTORY.should_not_receive(:push)
        @telnet.should_receive(:cmd).and_return("irb():002:0*> ")
        verify_console_exit("irb():002:0*> ")

        @console.start_console
      end

      it "should not keep identical commands in history" do
        @telnet.should_receive(:login).with(@creds[:telnet]).and_return("irb():001:0> ")
        Readline.should_receive(:readline).with("irb():001:0> ") { "puts 'hi'" }
        Readline::HISTORY.should_receive(:to_a).and_return(["puts 'hi'"])
        Readline::HISTORY.should_not_receive(:push).with("puts 'hi'")
        @telnet.should_receive(:cmd).with("puts 'hi'").and_return("nil" + "\n" + "irb():002:0> ")
        @console.should_receive(:puts).with("nil")
        verify_console_exit("irb():002:0> ")

        @console.start_console
      end

      it "should return tab completion data" do
        @telnet.should_receive(:login).with(@creds[:telnet]).and_return("Switch to inspect mode\nirb():001:0> ")
        @telnet.should_receive(:cmd).with("String" => "app.\t", "Match" => /\S*\n$/, "Timeout" => 10) { "to_s,nil?\n" }
        verify_console_exit("irb():001:0> ")

        @console.start_console
        Readline.completion_proc.call("app.").should == ["to_s","nil?"]
      end

      it "should return tab completion data receiving empty completion string" do
        @telnet.should_receive(:login).with(@creds[:telnet]).and_return("irb():001:0> ")
        @telnet.should_receive(:cmd).with("String" => "app.\t", "Match" => /\S*\n$/, "Timeout" => 10) { "\n" }
        verify_console_exit("irb():001:0> ")

        @console.start_console
        Readline.completion_proc.call("app.").should == []
      end

      it "should not crash on timeout of remote tab completion data" do
        @telnet.should_receive(:login).with(@creds[:telnet]).and_return("Switch to inspect mode\nirb():001:0> ")
        @telnet.should_receive(:cmd).with("String" => "app.\t", "Match" => /\S*\n$/, "Timeout" => 10) { raise TimeoutError }
        verify_console_exit("irb():001:0> ")

        @console.start_console
        Readline.completion_proc.call("app.").should == []
      end

      it "should properly initialize Readline for tab completion" do
        @telnet.should_receive(:login).with(@creds[:telnet]).and_return("irb():001:0> ")
        Readline.should_receive(:respond_to?).with("basic_word_break_characters=") { true }
        Readline.should_receive(:basic_word_break_characters=).with(" \t\n`><=;|&{(")
        Readline.should_receive(:completion_append_character=).with(nil)
        Readline.should_receive(:completion_proc=).with(anything)
        verify_console_exit("irb():001:0> ")

        @console.start_console
      end
    end
  end

  def verify_console_exit(prompt)
    Readline.should_receive(:readline).with(prompt) { "exit" }
    @telnet.should_receive(:cmd).with("String" => "exit", "Timeout" => 1) { raise TimeoutError }
    @telnet.should_receive(:close)
  end
end
