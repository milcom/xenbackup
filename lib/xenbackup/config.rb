module XenBackup

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :uri, :user, :pass, :backup, :tag, :ssl_validate

    # could set defaults here
    def initialize
      @uri = 'http://localhost'
      @user = 'root'
      @tag = 'xenbackup'
      @ssl_validate = true
    end
  end
end
