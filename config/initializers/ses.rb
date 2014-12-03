# Initializer for Amazon's SES email service.
# The only thing this initializer has to do is
# turn on tls in the Net::SMTP package.

require 'net/smtp'

module Net
  class SMTP
    def tls?
      true
    end
  end
end
