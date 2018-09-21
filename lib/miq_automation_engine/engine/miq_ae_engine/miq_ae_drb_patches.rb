require "drb/drb"
require "drb/unix"

# We are only interested in using UNIX Sockets, but the "feature" of looping
# through all available protocols leads to issues where the default, TCP socket
# is tried when a UNIX socket should be used.
#
# To prevent this we override the default protocol from TCP to UNIX and
# prevent the addition of new protocols by overriding add_protocol.
module DRb
  module DRbProtocol
    @protocol = [DRb::DRbUNIXSocket]

    def add_protocol(_prot)
      @protocol
    end
    module_function :add_protocol
  end
end
