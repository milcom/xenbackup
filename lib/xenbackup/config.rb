module XenBackup
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :uri, :user, :pass, :backup, :tag, :ssl_validate, :timeout

    # could set defaults here
    def initialize
      @uri = 'http://localhost'
      @user = 'root'
      @tag = 'xenbackup'
      @ssl_validate = true
      @timeout = 30
    end
  end
end
