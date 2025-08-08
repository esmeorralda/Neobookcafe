class NotesController < ApplicationController
  before_action :authenticate_user!
def index
  @notes = current_user.notes.includes(:book)
end

def new
  @note = Note.new
  @show_new_book_field = false
  @note.book_id = params[:book_id] if params[:book_id].present?

  if @note.book_id.present? && @note.book_id != "new_book"
    @chapters = Book.find_by(id: @note.book_id)&.chapters
  else
    @chapters = []
  end
end
def create
  @saved_note = nil

  ActiveRecord::Base.transaction do
    # 새 책 생성 or 기존 책 연결
    if params[:note][:book_id] == "new_book"
      book_title = params[:note][:book_title].presence || "제목 없는 책"
      @book = current_user.books.create!(title: book_title.strip)
    else
      @book = current_user.books.find(params[:note][:book_id])
    end

    # 새 챕터 생성 or 기존 챕터 연결
    chapter_id = params[:note][:chapter_id]
    if chapter_id.blank? && params[:note][:chapter_title].present?
      @chapter = @book.chapters.create!(title: params[:note][:chapter_title].strip)
    else
      @chapter = @book.chapters.find_by(id: chapter_id)
    end

    last_position = @book.notes.maximum(:position) || 0
    # 노트 생성
    @saved_note = @book.notes.create!(
      user_id: current_user.id, 
      chapter: @chapter,
      page_from: params[:note][:page_from],
      page_to: params[:note][:page_to],
      memo: params[:note][:memo],
      color: params[:note][:color],
      position: last_position + 1 
    )
  end

  if @saved_note.persisted?
     update_book_current_page(@book)
    redirect_to note_path(@saved_note), notice: "메모가 저장되었습니다."
  else
    render_failed_note
  end

rescue ActiveRecord::RecordInvalid => e
  flash[:alert] = "메모 저장 중 오류가 발생했습니다: #{e.message}"
  render_failed_note
end

def render_failed_note
  @show_new_book_field = params[:note][:book_id] == "new_book"
  @note ||= Note.new(note_params)  # 이 시점엔 note_params는 안전함
  @note.book_id = params[:note][:book_id]

  @chapters = if @note.book_id.present? && @note.book_id != "new_book"
    Book.find_by(id: @note.book_id)&.chapters || []
  else
    []
  end

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
  
   redirect_to books_path, notice: "노트가 삭제되었습니다." 
  end

  def edit
  @note = current_user.notes.find(params[:id])
  @chapters = @note.book.chapters
end

def update
  @note = current_user.notes.find(params[:id])
  
  if params[:note][:chapter_id] == "new_chapter"
    chapter = @note.book.chapters.create!(title: params[:note][:chapter_title])
    params[:note][:chapter_id] = chapter.id
  end

  if @note.update(note_params)
    update_book_current_page(@note.book) # 책의 current_page 자동 갱신
   redirect_to note_path(@note), notice: "노트가 성공적으로 업데이트되었습니다."

  else
    @chapters = @note.book.chapters
    render :edit, alert: "업데이트 실패"
  end
end

  
  private

def note_params
  params.require(:note).permit(
    :book_id, :chapter_id,
    :page_from, :page_to, :memo, :color
  )
end


def update_book_current_page(book)
  return unless book

  max_page_to = book.notes.maximum(:page_to) || 0

  if book.current_page.nil? || max_page_to > book.current_page
    book.update(current_page: max_page_to)
  end
end

end
