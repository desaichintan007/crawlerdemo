class Link < ActiveRecord::Base
  has_many :sublinks, :dependent => :delete_all
end
