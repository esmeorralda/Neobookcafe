class BooksController < ApplicationController
    before_action :authenticate_user!

    def index
      @books = Book.includes(:notes).order(created_at: :desc)
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

    def chapters_and_current_page
      book = Book.find(params[:book_id])
      chapters = book.chapters.select(:id, :title).order(:position)
    
      render json: {
        chapters: chapters.as_json(only: [:id, :title]),
        current_page: book.current_page || 0
      }
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
