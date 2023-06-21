# frozen_string_literal: true

class Error < StandardError
end

class SessionMissingError < Error
end

class UnauthorizedError < Error
end

class ForbiddenError < Error
end

class NoFolderSelectedError < Error
end

class CryptopusEncryptableNotFoundError < Error
end

class TeamNotFoundError < Error
end

class FolderNotFoundError < Error
end
