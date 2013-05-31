module InteractHelper
  def stub_ask(*args, &block)
    CF::CLI.any_instance.stub(:ask).with(*args, &block)
  end

  def mock_ask(*args, &block)
    CF::CLI.any_instance.should_receive(:ask).with(*args, &block)
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
