module XenBackup

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :uri, :user, :pass, :backup, :tag

    # could set defaults here
    def initialize
      @uri = 'http://localhost'
      @tag = 'xenbackup'
    end
  end
end
