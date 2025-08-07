module PostsHelper
    # rm public/assets/.manifest.json
#      bin/rails assets:clobber   # 기존 자산 캐시 삭제
# bin/rails assets:precompile  # 자산 재컴파일
# bin/rails server

def book_genre_radio_buttons(selected_genre = nil, name: "post[book_genre]")
    Post.book_genre_korean.map do |key, label|
      radio_button_tag(name, key, selected_genre.to_s == key.to_s) + " " + label
    end.join(" ").html_safe
  end
  
end
