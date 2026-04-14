-- lua_processor
local SubStringUTF8 = require("utf8_sub")

function init(env)
  -- 加载词典
  env.mem = Memory(env.engine, env.engine.schema)
end

local function is_word(code, env)
  local found = env.mem:dict_lookup(code, false, 1)
  return found
end
local function get_word(code, env)
  if env.mem:dict_lookup(code, false, 1) then
    for t in env.mem:iter_dict() do
      return t.text
    end
  end
end

local function commit(env, code, leftover)
  local text = get_word(code, env)
  if not text then return end

  env.engine:commit_text(text)
  env.engine.context:clear()

  if leftover and #leftover > 0 then
    env.engine.context.input = leftover
  end
end

-- 定义一个处理器
local function auto_commit(key_event, env)
  local context = env.engine.context
  local inp = context.input
  local com = env.engine.context.composition
  local seg = com:back()
  local i = 0

  if not com:empty() then
    if seg.start > 0 then ---上屏第一个选字,保留剩下的编码
      local t = context:get_commit_text()
      env.engine:commit_text(SubStringUTF8(t, 1, 1))
      env.engine.context:clear()
      context.input = inp:sub(seg.start + 1)
    end
  end


  inp = context.input
  local n = #inp
  local flag = true
  while flag do  ---循环处理,直到无法上屏
    flag = false ---控制跳出标志
    inp = context.input
    n = #inp

    if n >= 4 then
      local w3 = is_word(inp:sub(1, 3), env)
      local w4 = is_word(inp:sub(1, 4), env)
      if w3 and not w4 then
        commit(env, inp:sub(1, 3), inp:sub(4))
        flag = true
        ---这里要跳到下一次循环因为inp和n都要更新
      elseif not w3 and not w4 then
        flag = true
        context:clear()
        ---直接全部清空太极端了,或许可以在没有选项时提供两个选项让用户选择清空
      end
    end
    if not flag and n >= 5 then
      local w3 = is_word(inp:sub(1, 3), env)
      local w4 = is_word(inp:sub(1, 4), env)
      if not w3 and w4 then
        commit(env, inp:sub(1, 4), inp:sub(5))
        flag = true
      end
    end
    if not flag and n >= 7 then
      ---只需判断出第一个字是三码字还是四码字即可
      ---3+4 4+n 3+3+n
      ---若只能是三码字则得判断4+n的情况不存在,这需要第8码时才能判断
      ---只能是四码字则,3+4和3+3都不行,那么就是末四码不能成字且未四码前三码也不能成字
      local e4 = is_word(inp:sub(4, 7), env)
      local m3 = is_word(inp:sub(4, 6), env)
      if not e4 and not m3 then ---说明前面不能取三码字只能是四码字
        commit(env, inp:sub(1, 4), inp:sub(5))
        flag = true
      end
    end
    if not flag and n >= 8 then
      ---存在3+3+n 3+4+n 4+3+n 4+4
      ---只能取前四码成字的情况:3+3+n和3+4+n都不成立这种情会在7码时就判出,不用再判
      ---abcd efg h
      ---1234 567 8
      ---只能取前三码的情况:4+3+n和4+4都不成立,
      local e4 = is_word(inp:sub(5, 8), env)
      local es3 = is_word(inp:sub(5, 7), env)
      if not e4 and not es3 then
        commit(env, inp:sub(1, 3), inp:sub(4))
        flag = true
      end
    end
  end
  return 2
end


return {
  init = init,
  func = auto_commit,
}
