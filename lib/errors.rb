# frozen_string_literal: true

class Error < StandardError
end

class SessionMissingError < Error
end

class UnauthorizedError < Error
end
