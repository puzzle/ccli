# frozen_string_literal: true

class Error < StandardError
end

class SessionMissingError < Error
end

class UnauthorizedError < Error
end

class ForbiddenError < Error
end

class OpenshiftClientMissingError < Error
end

class OpenshiftClientNotLoggedInError < Error
end

class KubernetesClientMissingError < Error
end

class KubernetesClientNotLoggedInError < Error
end

class OpenshiftSecretNotFoundError < Error
end

class NoFolderSelectedError < Error
end

class CryptopusAccountNotFoundError < Error
end

class TeamNotFoundError < Error
end

class FolderNotFoundError < Error
end

class NotSecretsDirectoryError < Error
end
