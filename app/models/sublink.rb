class Sublink < ActiveRecord::Base
  belongs_to :link

  searchable :auto_index => true do
    text :content ,:stored => true, :more_like_this => true
    integer :link_id
  end
end
