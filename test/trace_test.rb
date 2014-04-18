module TraceTest
  class TraceTestCase < TestDsl::TestCase
    before do
      @example = -> do
        $bla = 5
        byebug
        $bla = 7
        $bla = 8
        $bla = 9
        $bla = 10
        $bla = (0 == (10 % $bla))
      end
      untrace_var(:$bla) if defined?($bla)
    end

    describe 'tracing' do
      describe 'enabling' do
        it 'must trace execution by setting trace to on' do
          enter 'trace on', 'cont 10', 'trace off'
          debug_proc(@example)
          check_output_includes 'line tracing is on.',
                                "Tracing: #{__FILE__}:8 $bla = 8",
                                "Tracing: #{__FILE__}:10 $bla = 10"
        end

        it 'must be able to use a shortcut' do
          enter 'tr on', 'cont 10', 'trace off'
          debug_proc(@example)
          check_output_includes 'line tracing is on.',
                                "Tracing: #{__FILE__}:8 $bla = 8",
                                "Tracing: #{__FILE__}:10 $bla = 10"
        end

        it 'must correctly print lines containing % sign' do
          enter 'cont 10', 'trace on', 'next', 'trace off'
          debug_proc(@example)
          check_output_includes "Tracing: #{__FILE__}:11 $bla = (0 == (10 % $bla))"
        end

        describe 'when basename set' do
          temporary_change_hash Byebug.settings, :basename, true

          it 'must correctly print file lines' do
            enter 'tr on', 'cont 10', 'trace off'
            debug_proc(@example)
            check_output_includes \
              "Tracing: #{File.basename(__FILE__)}:10 $bla = 10"
          end
        end
      end

      it 'must show an error message if given subcommand is incorrect' do
        enter 'trace bla'
        debug_proc(@example)
        check_error_includes \
          'expecting "on", "off", "var" or "variable"; got: "bla"'
      end

      describe 'disabling' do
        it 'must stop tracing by setting trace to off' do
          enter 'trace on', 'next', 'trace off'
          debug_proc(@example)
          check_output_includes "Tracing: #{__FILE__}:8 $bla = 8"
          check_output_doesnt_include "Tracing: #{__FILE__}:9 $bla = 9"
        end

        it 'must show a message when turned off' do
          enter 'trace off'
          debug_proc(@example)
          check_output_includes 'line tracing is off.'
        end
      end
    end

    describe 'tracing global variables' do
      it 'must track global variable' do
        enter 'trace variable bla'
        debug_proc(@example)
        check_output_includes "traced global variable 'bla' has value '7'",
                              "traced global variable 'bla' has value '10'"
      end

      it 'must be able to use a shortcut' do
        enter 'trace var bla'
        debug_proc(@example)
        check_output_includes "traced global variable 'bla' has value '7'"
                              "traced global variable 'bla' has value '10'"
      end

      it 'must track global variable with stop' do
        enter 'trace variable bla stop', 'break 10', 'cont'
        debug_proc(@example) { state.line.must_equal 8 }
      end

      it 'must track global variable with nostop' do
        enter 'trace variable bla nostop', 'break 10', 'cont'
        debug_proc(@example) { state.line.must_equal 10 }
      end

      describe 'errors' do
        it 'must show an error message if there is no such global variable' do
          enter 'trace variable foo'
          debug_proc(@example)
          check_error_includes "'foo' is not a global variable."
        end

        it 'must show an error message if subcommand is invalid' do
          enter 'trace variable bla foo'
          debug_proc(@example)
          check_error_includes 'expecting "stop" or "nostop"; got "foo"'
        end
      end
    end
  end
end
