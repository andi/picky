# This is very optional.
# Only load if the user wants it.
#
module Interfaces
  # This is an interface that provides the user of
  # Picky with the possibility to change parameters
  # while the Application is running.
  #
  # Important Note: This will only work in Master/Child configurations.
  #
  class LiveParameters
    
    def initialize
      @child, @parent = IO.pipe
      start_master_process_thread
    end
    
    # This runs a thread that listens to child processes.
    #
    def start_master_process_thread
      Thread.new do
        loop do
          sleep 1
          # @parent.close unless @parent.closed?
          result = @child.gets ';;;'
          pid, configuration_hash = eval result
          next unless Hash === configuration_hash
          next if configuration_hash.empty?
          puts "Trying to update MASTER configuration."
          try_updating_configuration_with configuration_hash
          kill_each_worker_except pid
          # TODO rescue on error.
        end
      end
    end
    
    # Taken from Unicorn.
    #
    def kill_each_worker_except pid
      Unicorn::HttpServer::WORKERS.keys.each do |wpid|
        next if wpid == pid
        kill_worker :KILL, wpid
      end
    end
    def kill_worker signal, wpid
      Process.kill signal, wpid
      puts "Killing worker ##{wpid} with signal #{signal}."
      rescue Errno::ESRCH
        worker = Unicorn::HttpServer::WORKERS.delete(wpid) and worker.tmp.close rescue nil
    end
    
    # Updates any parameters with the ones given and
    # returns the updated params.
    #
    # The params are a strictly defined hash of:
    #   * querying_removes_characters: Regexp
    #   * querying_stopwords:          Regexp
    #   TODO etc.
    #
    # This first tries to update in the child process,
    # and if successful, in the parent process
    #
    def parameters configuration_hash
      @child.close unless @child.closed?
      puts "Trying to update worker child configuration." unless configuration_hash.empty?
      try_updating_configuration_with configuration_hash
      @parent.write "#{[Process.pid, configuration_hash]};;;"
      extract_configuration
    rescue CouldNotUpdateConfigurationError => e
      # I need to die such that my broken config is never used.
      #
      puts "Child process #{Process.pid} performs harakiri because of broken config."
      Process.kill :QUIT, Process.pid
      { e.config_key => :ERROR }
    end
    
    class CouldNotUpdateConfigurationError < StandardError
      attr_reader :config_key
      def initialize config_key, message
        super message
        @config_key = config_key
      end
    end
    
    # Tries updating the configuration in the child process or parent process.
    # 
    def try_updating_configuration_with configuration_hash
      current_key = nil
      begin
        configuration_hash.each_pair do |key, new_value|
          puts "  Setting #{key} with #{new_value}."
          current_key = key
          send :"#{key}=", new_value
        end
      rescue StandardError => e
        raise CouldNotUpdateConfigurationError.new current_key, e.message
      end
    end
    
    def extract_configuration
      {
        querying_removes_characters: querying_removes_characters,
        querying_stopwords:          querying_stopwords,
        querying_splits_text_on:     querying_splits_text_on
      }
    end
    
    # TODO Move to Interface object.
    #
    def querying_removes_characters
      Tokenizers::Query.default.instance_variable_get(:@removes_characters_regexp).source
    end
    def querying_removes_characters= new_value
      Tokenizers::Query.default.instance_variable_set(:@removes_characters_regexp, %r{#{new_value}})
    end
    def querying_stopwords
      Tokenizers::Query.default.instance_variable_get(:@remove_stopwords_regexp).source
    end
    def querying_stopwords= new_value
      Tokenizers::Query.default.instance_variable_set(:@remove_stopwords_regexp, %r{#{new_value}})
    end
    def querying_splits_text_on
      Tokenizers::Query.default.instance_variable_get(:@splits_text_on_regexp).source
    end
    def querying_splits_text_on= new_value
      Tokenizers::Query.default.instance_variable_set(:@splits_text_on_regexp, %r{#{new_value}})
    end
    
  end
  
  # Aka.
  #
  ::LiveParameters = LiveParameters
  
end