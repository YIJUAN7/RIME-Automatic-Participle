---用于让长编码状态下始终显示前三码或是前四码候选,默认四码候选在前
function init(env)
  -- 创建 memory 对象，关联词典
  env.mem = Memory(env.engine, env.engine.schema)
end

local function func(input, seg, env)
  -- 查询词典
  if #input >= 4 then
    ---原为>4，修改为>=4,让四码时也显示三码候选项，这样可以避免输入四码无候选而三码有候选，这时触发前三码上屏，但是在上屏前的极短时间内会没有候选项，使候选框快速变小，完成上屏后又显示第四码前缀匹配出的选项，候选框又变大，这样会在视觉上产生快速闪烁。
    ---先添加四码候选,再添加三码,可以调换顺序
    ---或者控制第一项显示四码首选,第二项显示三码首选
    if env.mem:dict_lookup(input:sub(1, 4), false, 100) then
      for entry in env.mem:iter_dict() do
        yield(Candidate("dict", seg.start + 1, seg.start + 4, entry.text, entry.comment or ""))
      end
    end

    if env.mem:dict_lookup(input:sub(1, 3), false, 100) then
      for entry in env.mem:iter_dict() do
        yield(Candidate("dict", seg.start + 1, seg.start + 3, entry.text, entry.comment or ""))
      end
    end
  end
end

return { init = init, func = func }
-- return { func = func }
