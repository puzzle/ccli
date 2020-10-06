# frozen_string_literal: true

class Folder
  attr_reader :name, :id

  def initialize(name: nil, id: nil)
    @name = name
    @id = id
  end
end
