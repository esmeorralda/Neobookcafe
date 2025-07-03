class BooksController < ApplicationController
    before_action :authenticate_user!

    def index
      @books = Book.includes(:notes).order(created_at: :desc)
    end
    
    def show
      @book = current_user.books.find(params[:id])
      @notes = @book.notes
    end
  
    def new
      @book = current_user.books.new
    end
  
    def create
      @book = current_user.books.new(book_params)
      if @book.save
        redirect_to @book, notice: "책이 등록되었습니다."
      else
        render :new
      end
    end
  
    private
  
    def book_params
      params.require(:book).permit(:title)
    end
end
