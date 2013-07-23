module InteractHelper
  def stub_ask(*args, &block)
    CF::CLI.any_instance.stub(:ask).with(*args, &block)
  end

  def should_ask(*args, &block)
    CF::CLI.any_instance.should_receive(:ask).with(*args, &block)
  end

  def should_print(*args, &block)
    CF::CLI.any_instance.should_receive(:line).with(*args, &block)
  end

  def should_print_error(*args, &block)
    CF::CLI.any_instance.should_receive(:err).with(*args, &block)
  end

  def dont_allow_ask(*args)
    CF::CLI.any_instance.should_not_receive(:ask).with(*args)
  end

  def mock_with_progress(message)
    CF::CLI.any_instance.should_receive(:with_progress).with(message) do |_, &block|
      block.call
    end
  end
end
