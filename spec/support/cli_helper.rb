module CliHelper
  def stub_client_and_precondition
    stub_client
    stub_precondition
  end

  def stub_client
    described_class.any_instance.stub(:client).and_return(client)
  end

  def stub_precondition
    described_class.any_instance.stub(:precondition)
  end

  def wrap_errors
    yield
  rescue CF::UserError => e
    err e.message
  end

  def cf(argv)
    Mothership.new.exit_status 0
    CF::CLI.stub(:exit) { |code| code }
    capture_output { CF::CLI.start(argv + ["--debug", "--no-script"]) }
  end

  def bool_flag(flag)
    "#{'no-' unless send(flag)}#{flag.to_s.gsub('_', '-')}"
  end

  attr_reader :stdout, :stderr, :stdin, :status

  def capture_output
    $real_stdout = $stdout
    $real_stderr = $stderr
    $real_stdin = $stdin
    $stdout = @stdout = StringIO.new
    $stderr = @stderr = StringIO.new
    $stdin = @stdin = StringIO.new
    @status = yield
    @stdout.rewind
    @stderr.rewind
    @status
  ensure
    $stdout = $real_stdout
    $stderr = $real_stderr
    $stdin = $real_stdin
  end

  def capture_exceptional_output
    $real_stdout = $stdout
    $real_stderr = $stderr
    $real_stdin = $stdin
    $stdout = @stdout = StringIO.new
    $stderr = @stderr = StringIO.new
    $stdin = @stdin = StringIO.new
    begin
      @status = yield
    rescue => e
      @stderr.write(e.message)
    end
    @stdout.rewind
    @stderr.rewind
    @status
  ensure
    $stdout = $real_stdout
    $stderr = $real_stderr
    $stdin = $real_stdin
  end


  def output
    @output ||= BlueShell::BufferedReaderExpector.new(stdout)
  end

  def error_output
    @error_output ||= BlueShell::BufferedReaderExpector.new(stderr)
  end

  def mock_invoke(*args)
    described_class.any_instance.should_receive(:invoke).with(*args)
  end

  def dont_allow_invoke(*args)
    described_class.any_instance.should_not_receive(:invoke).with(*args)
  end
end
