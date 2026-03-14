# frozen_string_literal: true

require 'legion/extensions/cortex/version'
require 'legion/extensions/cortex/helpers/wiring'
require 'legion/extensions/cortex/helpers/signal_buffer'
require 'legion/extensions/cortex/helpers/runner_host'
require 'legion/extensions/cortex/runners/cortex'

module Legion
  module Extensions
    module Cortex
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
