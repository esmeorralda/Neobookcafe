# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_16_061722) do
  create_table "bookmarks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_bookmarks_on_post_id"
    t.index ["user_id", "post_id"], name: "index_bookmarks_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "title"
    t.string "author"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "total_pages"
    t.integer "current_page"
    t.index ["user_id"], name: "index_books_on_user_id"
  end

  create_table "chapters", force: :cascade do |t|
    t.string "title"
    t.integer "position"
    t.integer "book_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_chapters_on_book_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.integer "post_id"
    t.integer "user_id", null: false
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "post_block_id"
    t.integer "highlight_start"
    t.integer "highlight_end"
    t.index ["post_block_id"], name: "index_comments_on_post_block_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "likeable_type", null: false
    t.integer "likeable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.integer "book_id", null: false
    t.integer "page_from"
    t.integer "page_to"
    t.string "chapter"
    t.string "color"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "chapter_id", null: false
    t.integer "position"
    t.index ["book_id"], name: "index_notes_on_book_id"
    t.index ["chapter_id"], name: "index_notes_on_chapter_id"
  end

  create_table "post_blocks", force: :cascade do |t|
    t.integer "post_id", null: false
    t.text "content"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "block_type", default: 0, null: false
    t.index ["content"], name: "index_post_blocks_on_content"
    t.index ["post_id"], name: "index_post_blocks_on_post_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.string "book_title"
    t.string "book_author"
    t.integer "save_count"
    t.integer "like_count"
    t.integer "view_count"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category", default: 0, null: false
    t.boolean "draft", default: false, null: false
    t.boolean "allow_comments", default: true
    t.integer "book_genre", default: 0, null: false
    t.index ["book_author"], name: "index_posts_on_book_author"
    t.index ["book_title"], name: "index_posts_on_book_title"
    t.index ["title"], name: "index_posts_on_title"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.index ["name"], name: "index_users_on_name"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bookmarks", "posts"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "books", "users"
  add_foreign_key "chapters", "books"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "likes", "users"
  add_foreign_key "notes", "books"
  add_foreign_key "notes", "chapters"
  add_foreign_key "post_blocks", "posts"
  add_foreign_key "posts", "users"
end
