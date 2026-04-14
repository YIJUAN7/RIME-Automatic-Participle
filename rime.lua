---简单示例
function get_date(input, seg, env)
  --- 以 show_date 为开关名或 key_binder 中 toggle 的对象
  if (input == "date") then
    --- Candidate(type, start, end, text, comment)
    yield(Candidate("date", seg.start, seg._end, os.date("%Y年%m月%d日"), " 日期"))
  end
end