-- 在创建表之前先删除旧数据（如果存在）
DROP TABLE IF EXISTS sentences;
DROP TABLE IF EXISTS root_relations;
DROP TABLE IF EXISTS learning_records;
DROP TABLE IF EXISTS words;
DROP TABLE IF EXISTS roots;
DROP TABLE IF EXISTS affixes;

-- 创建词根表
CREATE TABLE IF NOT EXISTS roots (
    id TEXT PRIMARY KEY,
    text TEXT NOT NULL,
    meaning TEXT NOT NULL,
    description TEXT NOT NULL
);

-- 创建单词表
CREATE TABLE IF NOT EXISTS words (
    id TEXT PRIMARY KEY,
    text TEXT NOT NULL,
    meaning TEXT NOT NULL,
    root TEXT NOT NULL,
    prefix TEXT,
    suffix TEXT,
    pronunciation TEXT NOT NULL
);

-- 创建词缀表
CREATE TABLE IF NOT EXISTS affixes (
    id TEXT PRIMARY KEY,
    text TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('prefix', 'suffix')),
    meaning TEXT NOT NULL
);

-- 创建例句表
CREATE TABLE IF NOT EXISTS sentences (
    id TEXT PRIMARY KEY,
    word_id TEXT NOT NULL,
    text TEXT NOT NULL,
    translation TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(word_id) REFERENCES words(id)
);

-- 创建词根关系表
CREATE TABLE IF NOT EXISTS root_relations (
    id TEXT PRIMARY KEY,
    root1_id TEXT NOT NULL,
    root2_id TEXT NOT NULL,
    relation_type TEXT NOT NULL,
    description TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(root1_id) REFERENCES roots(id),
    FOREIGN KEY(root2_id) REFERENCES roots(id)
);

-- 创建学习记录表
CREATE TABLE IF NOT EXISTS learning_records (
    id TEXT PRIMARY KEY,
    date DATE NOT NULL,
    minutes INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 清空所有表（以防万一）
DELETE FROM sentences;
DELETE FROM root_relations;
DELETE FROM learning_records;
DELETE FROM words;
DELETE FROM roots;
DELETE FROM affixes;

-- 插入示例数据
INSERT INTO roots (id, text, meaning, description) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'port', '港口，运送', '来自拉丁语 portare，表示携带、运送'),
('550e8400-e29b-41d4-a716-446655440001', 'duc', '引导', '来自拉丁语 ducere，表示引导、带领'),
('550e8400-e29b-41d4-a716-446655440002', 'mit', '发送', '来自拉丁语 mittere，表示发送、投递'),
('550e8400-e29b-41d4-a716-446655440010', 'happi', '快乐', '来自古英语 hap，表示运气、机遇，引申为快乐、幸福');

INSERT INTO words (id, text, meaning, root, prefix, suffix, pronunciation) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'port', '港口', 'port', NULL, NULL, 'pɔːrt'),
('550e8400-e29b-41d4-a716-446655440001', 'export', '出口', 'port', 'ex', NULL, 'ɪkˈspɔːrt'),
('550e8400-e29b-41d4-a716-446655440002', 'import', '进口', 'port', 'im', NULL, 'ɪmˈpɔːrt'),
('550e8400-e29b-41d4-a716-446655440003', 'conduct', '指导，引导', 'duc', 'con', NULL, 'kənˈdʌkt'),
('550e8400-e29b-41d4-a716-446655440004', 'submit', '提交', 'mit', 'sub', NULL, 'səbˈmɪt'),
('550e8400-e29b-41d4-a716-446655440013', 'unhappiness', '不快乐', 'happi', 'un', 'ness', 'ʌnˈhæpinəs'),
('550e8400-e29b-41d4-a716-446655440015', 'happy', '快乐的', 'happi', NULL, NULL, 'ˈhæpi'),
('550e8400-e29b-41d4-a716-446655440016', 'happiness', '快乐', 'happi', NULL, 'ness', 'ˈhæpinəs'),
('550e8400-e29b-41d4-a716-446655440017', 'unhappy', '不快乐的', 'happi', 'un', NULL, 'ʌnˈhæpi');

INSERT INTO affixes (id, text, type, meaning) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'ex', 'prefix', '向外，出'),
('550e8400-e29b-41d4-a716-446655440001', 'im', 'prefix', '向内，进'),
('550e8400-e29b-41d4-a716-446655440002', 'con', 'prefix', '共同'),
('550e8400-e29b-41d4-a716-446655440003', 'sub', 'prefix', '在下，次要的'),
('550e8400-e29b-41d4-a716-446655440011', 'un', 'prefix', '表示"不，相反"'),
('550e8400-e29b-41d4-a716-446655440012', 'ness', 'suffix', '表示"性质，状态"');

INSERT INTO sentences (id, word_id, text, translation) VALUES
('550e8400-e29b-41d4-a716-446655440014', '550e8400-e29b-41d4-a716-446655440013', 
'His unhappiness was visible to everyone.', '他的不快乐被所有人看在眼里。');

INSERT INTO root_relations (id, root1_id, root2_id, relation_type, description) VALUES
('550e8400-e29b-41d4-a716-446655440020', 
 '550e8400-e29b-41d4-a716-446655440010', 
 '550e8400-e29b-41d4-a716-446655440000', 
 '相关', 'happy（快乐）和 port（运送）都与积极情感相关'); 