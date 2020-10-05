# frozen_string_literal: true

class Folder
  attr_reader :name, :id

  def initialize(name, id: nil)
    @name = name
    @id = id
  end
end
