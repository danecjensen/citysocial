module Restaurants
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
