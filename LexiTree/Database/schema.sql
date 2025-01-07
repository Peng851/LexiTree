-- 修改sentences表，添加中文翻译字段
CREATE TABLE IF NOT EXISTS sentences (
    id TEXT PRIMARY KEY,
    word_id TEXT NOT NULL,
    text TEXT NOT NULL,
    translation TEXT NOT NULL,  -- 已经有了，不需要修改
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(word_id) REFERENCES words(id)
); 