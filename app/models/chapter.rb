class Chapter < ApplicationRecord
    belongs_to :book, optional: true
    has_many :notes
  
    before_create :set_position
  
    private
  
    def set_position
      if book_id
        self.position = Chapter.where(book_id: book_id).order(:created_at).count + 1
      else
        self.position = nil
      end
    end
  end
  