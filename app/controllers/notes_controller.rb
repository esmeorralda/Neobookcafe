class NotesController < ApplicationController
  before_action :authenticate_user!

  def new
    @note = Note.new
    @show_new_book_field = false
     # URL 파라미터로 들어온 book_id가 있으면 미리 설정
  @note.book_id = params[:book_id] if params[:book_id].present?

  # 책에 따른 목차도 미리 로드
  if @note.book_id
    @chapters = Book.find_by(id: @note.book_id)&.chapters
  end
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
  
    ActiveRecord::Base.transaction do
      max_position = @book.notes.lock.maximum(:position) || 0
      @note.position = max_position + 1
      @note.save!
    end
  
    update_book_current_page(@note.book)
    redirect_to note_path(@note), notice: "메모가 저장되었습니다."
  
  rescue ActiveRecord::RecordInvalid
    @show_new_book_field = params[:note][:book_id] == "new_book"
    render :new
  end
  

  def show
    @note = Note.find(params[:id])
  end
  
  def destroy
    @note = current_user.notes.find(params[:id])
    book = @note.book
    @note.destroy
  
    # 노트 삭제 후 해당 책에 노트가 하나도 없으면 책도 삭제
    if book.notes.count.zero?
      book.destroy
    else
      update_book_current_page(book)
    end
  
    redirect_to notes_path, notice: "노트가 삭제되었습니다."
  end
  
  private

  def note_params
    params.require(:note).permit(:color, :memo, :page_from, :page_to)
  end

  def update_book_current_page(book)
    return unless book

    # book의 노트 중 가장 큰 page_to 찾기 (최대 읽은 페이지)
    max_page_to = book.notes.maximum(:page_to) || 0

    # 현재 current_page 보다 크면 업데이트
    if book.current_page.nil? || max_page_to > book.current_page
      book.update(current_page: max_page_to)
    end
  end
end
