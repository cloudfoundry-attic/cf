require "net/telnet"
require "readline"

require "tunnel/tunnel"

class CFConsole < CFTunnel
  def initialize(client, app, port = 10000)
    @client = client
    @app = app
    @port = port
  end

  def get_connection_info(auth)
    instances = @app.instances
    if instances.empty?
      raise "App has no running instances; try starting it."
    end

    unless console = instances[0].console
      raise "App does not have console access; try restarting it."
    end

    { "hostname" => console[:ip],
      "port" => console[:port]
    }
  end

  def get_credentials
    YAML.load(@app.file("app", "cf-rails-console", ".consoleaccess"))
  end

  def start_console
    prompt = login

    init_readline

    run_console prompt
  end

  def login(auth = get_credentials)
    if !auth["username"] || !auth["password"]
      raise "Unable to verify console credentials."
    end

    @telnet = telnet_client

    prompt = nil
    err_msg = "Login attempt timed out."

    5.times do
      begin
        results = @telnet.login(
          "Name" => auth["username"],
          "Password" => auth["password"])

        lines = results.sub("Login: Password: ", "").split("\n")

        last_line = lines.pop

        if last_line =~ /[$%#>] \z/n
          prompt = last_line
        elsif last_line =~ /Login failed/
          err_msg = last_line
        end

        break

      rescue TimeoutError
        sleep 1

      rescue EOFError
        # This may happen if we login right after app starts
        close_console
        sleep 5
        @telnet = telnet_client
      end
    end

    unless prompt
      close_console
      raise err_msg
    end

    prompt
  end

  private

  def init_readline
    if Readline.respond_to?("basic_word_break_characters=")
      Readline.basic_word_break_characters= " \t\n`><=;|&{("
    end

    Readline.completion_append_character = nil

    # Assumes that sending a String ending with tab will return a non-empty
    # String of comma-separated completion options, terminated by a new line
    # For example, "app.\t" might result in "to_s,nil?,etc\n"
    Readline.completion_proc = proc do |s|
      console_tab_completion_data(s)
    end
  end

  def run_console(prompt)
    prev = trap("INT")  { |x| exit_console; prev.call(x); exit }
    prev = trap("TERM") { |x| exit_console; prev.call(x); exit }

    loop do
      cmd = readline_with_history(prompt)

      if cmd == nil
        exit_console
        break
      end

      prompt = send_console_command_display_results(cmd, prompt)
    end
  end

  def readline_with_history(prompt)
    line = Readline::readline(prompt)

    return if line == nil || line == 'quit' || line == 'exit'

    if line !~ /^\s*$/ && Readline::HISTORY.to_a.last != line
      Readline::HISTORY.push(line)
    end

    line
  end

  def send_console_command_display_results(cmd, prompt)
    begin
      lines = send_console_command cmd

      # Assumes the last line is a prompt
      prompt = lines.pop

      lines.each do |line|
        puts line if line != cmd
      end

    rescue TimeoutError
      puts "Timed out sending command to server."

    rescue EOFError
      raise "The console connection has been terminated. Perhaps the app was stopped or deleted?"
    end

    prompt
  end

  def send_console_command(cmd)
    results = @telnet.cmd(cmd)
    results.split("\n")
  end

  def exit_console
    @telnet.cmd("String" => "exit", "Timeout" => 1)
  rescue TimeoutError
    # TimeoutError expected, as exit doesn't return anything
  ensure
    close_console
  end

  def close_console
    @telnet.close
  end

  def console_tab_completion_data(cmd)
    begin
      results = @telnet.
          cmd("String" => cmd + "\t", "Match" => /\S*\n$/, "Timeout" => 10)
      results.chomp.split(",")
    rescue TimeoutError
      [] #Just return empty results if timeout occurred on tab completion
    end
  end

  def telnet_client
    Net::Telnet.new(
      "Port" => @port,
      "Prompt" => /[$%#>] \z|Login failed/n,
      "Timeout" => 90,
      "FailEOF" => true)
  end
end
