class ChaptersController < ApplicationController
  def index
    book = Book.find(params[:book_id])
    chapters = book.chapters.select(:id, :title).order(:position)
    render json: chapters
  end
end
