# frozen_string_literal: true

require_relative "../abstract_unit"

class LoggingAssertionsTest < ActiveSupport::TestCase
  test "#capture_logs captures output for a block" do
    logger = ActiveSupport::Logger.new(StringIO.new)

    captured = capture_logs(logger) { logger.info "Hello, world" }

    assert_equal "Hello, world\n", captured
  end

  test "#assert_logged asserts the String equality of content logged during the block" do
    logger = ActiveSupport::Logger.new(StringIO.new)

    assert_logged("Hello, world\n", logger) do
      logger.info "Hello, world"
    end

    assert_raises Minitest::Assertion do
      assert_logged("Z", logger) { logger.info "A" }
    end
  end

  test "#assert_logged asserts a Regexp match against the content logged during the block" do
    logger = ActiveSupport::Logger.new(StringIO.new)

    assert_logged(/Hello, world/, logger) do
      logger.info "Hello, world"
    end

    assert_raises Minitest::Assertion do
      assert_logged(/Z/, logger) { logger.info "A" }
    end
  end

  test "#assert_not_logged asserts the String equality of content logged during the block" do
    logger = ActiveSupport::Logger.new(StringIO.new)

    assert_not_logged("Hello, world\n", logger) do
      logger.info "Goodbye, world"
    end

    assert_raises Minitest::Assertion do
      assert_not_logged("Hello, world\n", logger) { logger.info "Hello, world" }
    end
  end

  test "#assert_not_logged asserts a Regexp match against the content logged during the block" do
    logger = ActiveSupport::Logger.new(StringIO.new)

    assert_not_logged(/Hello, world/, logger) do
      logger.info "Goodbye, world"
    end

    assert_raises Minitest::Assertion do
      assert_not_logged(/Hello, world/, logger) { logger.info "Hello, world" }
    end
  end

  test "#assert_not_logged can omit the value argument" do
    logger = ActiveSupport::Logger.new(StringIO.new)

    assert_not_logged logger do
      # do nothing
    end

    assert_raises Minitest::Assertion do
      assert_not_logged(logger) { logger.info "Hello, world" }
    end
  end
end
