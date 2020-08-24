# frozen_string_literal: true

class Error < StandardError
end

class SessionMissingError < Error
end

class UnauthorizedError < Error
end

class OpenshiftClientMissingError < Error
end

class OpenshiftClientNotLoggedInError < Error
end

class OpenshiftSecretNotFoundError < Error
end

class NoFolderSelectedError < Error
end
