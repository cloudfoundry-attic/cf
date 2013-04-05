module CliHelper
  def stub_client_and_precondition
    stub_client
    stub_precondition
  end

  def stub_client
    any_instance_of described_class do |cli|
      stub(cli).client { client }
    end
  end

  def stub_precondition
    any_instance_of described_class do |cli|
      stub(cli).precondition
    end
  end

  def wrap_errors
    yield
  rescue CF::UserError => e
    err e.message
  end

  def cf(argv)
    Mothership.new.exit_status 0
    stub(CF::CLI).exit { |code| code }
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

  def output
    @output ||= TrackingExpector.new(stdout)
  end

  def error_output
    @error_output ||= TrackingExpector.new(stderr)
  end

  def mock_invoke(*args)
    any_instance_of described_class do |cli|
      mock(cli).invoke *args
    end
  end

  def dont_allow_invoke(*args)
    any_instance_of described_class do |cli|
      dont_allow(cli).invoke *args
    end
  end

end
