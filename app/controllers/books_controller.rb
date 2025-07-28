class BooksController < ApplicationController
    before_action :authenticate_user!
    # app/controllers/books_controller.rb
# app/controllers/books_controller.rb
def chapters_and_current_page

  book = Book.find(params[:id])
  if book.nil?
    render json: { error: "책을 찾을 수 없습니다." }, status: :not_found
    return
  end

  render json: {
    chapters: book.chapters.select(:id, :title),
    current_page: book.current_page
  }
end

 def index
  @books = current_user.books.includes(:notes)
end
    
    def edit
      @book = current_user.books.find(params[:id])
    end
    
    def update
      @book = current_user.books.find(params[:id])
      
      if @book.update(book_params)
        redirect_to @book, notice: "책 정보가 수정되었습니다."
      else
        render :edit
      end
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
      if action_name == "create"
        params.require(:book).permit(:title)
      else # update 등
        params.require(:book).permit(:title, :author, :total_pages)
      end
    end
    



end
