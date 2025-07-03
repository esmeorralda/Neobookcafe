class NotesController < ApplicationController
  before_action :authenticate_user!

  def new
    @note = Note.new
    @show_new_book_field = false
  end

  def create
    if params[:note][:book_id] == "new_book"
      @book = current_user.books.create(title: params[:note][:book_title])
    else
      @book = current_user.books.find_by(id: params[:note][:book_id])
    end

    if @book.nil?
      flash[:alert] = "책을 선택하거나 제목을 입력해주세요."
      redirect_to new_note_path and return
    end

    if params[:note][:chapter_id] == "new_chapter"
      @chapter = @book.chapters.create(title: params[:note][:chapter_title])
    elsif params[:note][:chapter_id].present?
      @chapter = Chapter.find_by(id: params[:note][:chapter_id])
    end

    @note = @book.notes.new(note_params)
    @note.chapter = @chapter if @chapter.present?

    max_position = @book.notes.maximum(:position) || 0
  @note.position = max_position + 1

    if @note.save
      redirect_to note_path(@note), notice: "메모가 저장되었습니다."
    else
      @show_new_book_field = params[:note][:book_id] == "new_book"
      render :new
    end
  end


  def show
    @note = Note.find(params[:id])
  end
  
  private

  def note_params
    params.require(:note).permit(:color, :memo, :page_from, :page_to)
  end

end
