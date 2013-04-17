require "spec_helper"

describe "CFConsole" do
  before do
    @app = mock("app")
    @console = CFConsole.new(nil, @app)
  end

  it "should return connection info for apps that have a console ip and port" do
    instance = mock("instance")
    mock(@app).instances { [instance] }
    mock(instance).console { {:ip => "192.168.1.1", :port => 3344} }

    @console.get_connection_info(nil).should == {
      "hostname" => "192.168.1.1",
      "port" => 3344
    }
  end

  it "should raise error when no app instances found" do
    mock(@app).instances { [] }

    expect {
      @console.get_connection_info(nil)
    }.to raise_error("App has no running instances; try starting it.")
  end

  it "should raise error when app does not have console access" do
    instance = mock("instance")
    mock(@app).instances { [instance] }
    mock(instance).console { nil }

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
        mock(@app).file(*@creds[:path]) { "username: cfuser" }

        expect {
          @console.start_console
        }.to raise_error("Unable to verify console credentials.")
      end
    end

    context "when console credentials can be obtained" do
      before do
        mock(@app).file(*@creds[:path]) { @creds[:yaml] }
        @telnet = Object.new
        mock(@console).telnet_client { @telnet }
      end

      it "should raise error if authentication fails" do
        mock(@telnet).login(@creds[:telnet]) { "Login failed" }
        mock(@telnet).close

        expect { @console.start_console }.to raise_error("Login failed")
      end

      it "should retry authentication on timeout" do
        mock(@telnet).login(@creds[:telnet]){ raise TimeoutError }
        mock(@telnet).login(@creds[:telnet]) { "Switch to inspect mode\nirb():001:0> " }
        verify_console_exit("irb():001:0> ")

        @console.start_console
      end

      it "should retry authentication on EOF" do
        mock(@console).telnet_client { @telnet }
        mock(@telnet).login(@creds[:telnet]) { raise EOFError }
        mock(@telnet).close
        mock(@telnet).login(@creds[:telnet]) { "irb():001:0> " }
        verify_console_exit("irb():001:0> ")

        @console.start_console
      end

      it "should operate console interactively" do
        mock(@telnet).login(@creds[:telnet]) { "irb():001:0> " }
        mock(Readline).readline("irb():001:0> ") { "puts 'hi'" }
        mock(Readline::HISTORY).push("puts 'hi'")
        mock(@telnet).cmd("puts 'hi'") { "nil" + "\n" + "irb():002:0> " }
        mock(@console).puts("nil")
        verify_console_exit("irb():002:0> ")

        @console.start_console
      end

      it "should not crash if command times out" do
        mock(@telnet).login(@creds[:telnet]) { "irb():001:0> " }
        mock(Readline).readline("irb():001:0> ") { "puts 'hi'" }
        mock(Readline::HISTORY).push("puts 'hi'")
        mock(@telnet).cmd("puts 'hi'") { raise TimeoutError }
        mock(@console).puts("Timed out sending command to server.")
        verify_console_exit("irb():001:0> ")

        @console.start_console
      end

      it "should raise error if an EOF is received" do
        mock(@telnet).login(@creds[:telnet]) { "Switch to inspect mode\nirb():001:0> " }
        mock(Readline).readline("irb():001:0> ") { "puts 'hi'" }
        mock(Readline::HISTORY).push("puts 'hi'")
        mock(@telnet).cmd("puts 'hi'") { raise EOFError }

        expect {
          @console.start_console
        }.to raise_error("The console connection has been terminated. Perhaps the app was stopped or deleted?")
      end

      it "should not keep blank lines in history" do
        mock(@telnet).login(@creds[:telnet]) { "irb():001:0> " }
        mock(Readline).readline("irb():001:0> ") { "" }
        dont_allow(Readline::HISTORY).push("")
        mock(@telnet).cmd("") { "irb():002:0*> " }
        verify_console_exit("irb():002:0*> ")

        @console.start_console
      end

      it "should not keep identical commands in history" do
        mock(@telnet).login(@creds[:telnet]) { "irb():001:0> " }
        mock(Readline).readline("irb():001:0> ") { "puts 'hi'" }
        mock(Readline::HISTORY).to_a { ["puts 'hi'"] }
        dont_allow(Readline::HISTORY).push("puts 'hi'")
        mock(@telnet).cmd("puts 'hi'") { "nil" + "\n" + "irb():002:0> " }
        mock(@console).puts("nil")
        verify_console_exit("irb():002:0> ")

        @console.start_console
      end

      it "should return tab completion data" do
        mock(@telnet).login(@creds[:telnet]) { "Switch to inspect mode\nirb():001:0> " }
        mock(@telnet).cmd("String" => "app.\t", "Match" => /\S*\n$/, "Timeout" => 10) { "to_s,nil?\n" }
        verify_console_exit("irb():001:0> ")

        @console.start_console
        Readline.completion_proc.call("app.").should == ["to_s","nil?"]
      end

      it "should return tab completion data receiving empty completion string" do
        mock(@telnet).login(@creds[:telnet]) { "irb():001:0> " }
        mock(@telnet).cmd("String" => "app.\t", "Match" => /\S*\n$/, "Timeout" => 10) { "\n" }
        verify_console_exit("irb():001:0> ")

        @console.start_console
        Readline.completion_proc.call("app.").should == []
      end

      it "should not crash on timeout of remote tab completion data" do
        mock(@telnet).login(@creds[:telnet]) { "Switch to inspect mode\nirb():001:0> " }
        mock(@telnet).cmd("String" => "app.\t", "Match" => /\S*\n$/, "Timeout" => 10) { raise TimeoutError }
        verify_console_exit("irb():001:0> ")

        @console.start_console
        Readline.completion_proc.call("app.").should == []
      end

      it "should properly initialize Readline for tab completion" do
        mock(@telnet).login(@creds[:telnet]) { "irb():001:0> " }
        mock(Readline).respond_to?("basic_word_break_characters=") { true }
        mock(Readline).basic_word_break_characters=(" \t\n`><=;|&{(")
        mock(Readline).completion_append_character=(nil)
        mock(Readline).completion_proc=(anything)
        verify_console_exit("irb():001:0> ")

        @console.start_console
      end
    end
  end

  def verify_console_exit(prompt)
    mock(Readline).readline(prompt) { "exit" }
    mock(@telnet).cmd("String" => "exit", "Timeout" => 1) { raise TimeoutError }
    mock(@telnet).close
  end
end
