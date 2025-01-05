# 单词树，英文LexiTree

## 产品文档

### 1. 应用概述
这款背单词应用的核心功能是通过词根和词缀展示单词，帮助用户系统性地记忆词汇。不同于市面上的传统背单词软件，本应用聚焦于通过词根、词缀及相关单词的联系，构建更具逻辑和记忆性的学习方式。

### 2. 主要功能
(1) 单词页面
- 单词列表：按词根分类展示
- 单词搜索：支持拼音和中文搜索
- 单词详情：
  - 词根词缀分析
  - 例句展示

(2) 学习页面
- 词根学习：
  - 词根列表
  - 词根详情
  - 相关单词
  - 例句学习

(3) 我的页面
- 学习统计
  - 已学单词数
  - 已掌握词根数
  - 今日学习时长
- 设置
  - 发音设置（美音/英音）
  - 自动发音开关
- 分享功能

### 3. 界面设计
- 简洁现代的界面风格
- 符合用户审美和使用习惯
- 原生 iOS 设计规范

### 4. 音频系统
✓ 在线 TTS API 集成
✓ 在线音频播放
✓ 美音/英音切换
✓ 自动发音功能

### 5. 开发者指南
#### 数据库管理
1. 词库管理
   - 使用 vocabulary.txt 管理词库数据
   - 格式：word|translation|components|pronunciation|example
   - 示例：
     ```
     unhappiness|不快乐|un:前缀:否定;happy:词根:快乐;ness:后缀:状态|/ʌnˈhæpɪnəs/|"His unhappiness was evident." ~ "他的不快乐很明显。"
     ```
   
2. 词库格式说明
   - 字段用 | 分隔
   - components 字段：
     - 组件之间用 ; 分隔
     - 每个组件的名称、类型、含义用 : 分隔
   - example 字段：
     - 英文例句和中文翻译用 ~ 分隔
     - 例句用引号包围

3. 词库更新流程
   1. 编辑 vocabulary.txt 添加新词条
   2. 运行 generate_db 生成新数据库
   3. 重新运行应用查看更新

4. 工具说明
   - DatabaseGenerator：词库解析和数据库生成工具
   - generate_db：命令行工具，用于生成数据库

### 6. 后续功能
- 用户自定义单词组
- 智能词根推荐
- 学习数据分析
- 社区分享功能

### 7. 技术架构
- 开发环境：Xcode
- 开发语言：Swift
- UI 框架：SwiftUI
- 目标平台：iOS 15.0+
- 平台特性：
  - iOS 16+：使用新的 ShareLink API
  - iOS 15：使用 UIActivityViewController
- 并发模型：
  - @MainActor 用于 UI 和数据管理
  - 异步数据操作
  - Actor 隔离保证线程安全
- 数据存储：
  - 主存储引擎：SQLite
  - 数据导出格式：JSON（便于人工维护）
  - 远程同步：后端服务器（可选）
- 音频系统：
  - 在线 TTS API
  - 在线音频播放
  - 美音/英音切换支持

### 8. 项目结构
```
LexiTree/                  # 项目根目录
├── README.md             # 项目说明文档
└── LexiTree/             # Xcode 项目目录
    ├── LexiTree/         # 主要源代码目录
    │   ├── App/         # 应用程序入口
    │   │   └── LexiTreeApp.swift
    │   ├── Models/      # 数据模型
    │   │   ├── Word.swift
    │   │   ├── Root.swift
    │   │   ├── Affix.swift
    │   │   ├── DTOs.swift
    │   │   ├── ExportData.swift
    │   │   └── RootRelation.swift
    │   ├── Services/    # 核心服务
    │   │   ├── DataManager.swift
    │   │   ├── AudioService.swift
    │   │   └── WordRepository.swift
    │   ├── ViewModels/  # 视图模型
    │   │   ├── RootListViewModel.swift
    │   │   ├── WordListViewModel.swift
    │   │   ├── StudyViewModel.swift
    │   │   ├── ProfileViewModel.swift
    │   │   └── RootNetworkViewModel.swift
    │   ├── Views/       # 用户界面
    │   │   ├── ContentView.swift
    │   │   ├── RootListView.swift
    │   │   ├── WordListView.swift
    │   │   ├── WordDetailView.swift
    │   │   ├── RootNetworkView.swift
    │   │   ├── StudyView.swift
    │   │   ├── ProfileView.swift
    │   │   └── ShareAppView.swift
    │   └── Preview Content/  # 预览数据
    │       ├── PreviewData.swift
    │       └── PreviewHelper.swift
    ├── Database/        # 数据库文件
    │   ├── schema.sql
    │   └── lexitree.db
    ├── LexiTreeTests/   # 单元测试
    ├── LexiTreeUITests/ # UI测试
    └── LexiTree.xcodeproj
```

### 9. 项目进度
第一阶段：
- [x] 项目基础架构搭建
- [x] 词根词缀展示
- [ ] 在线音频播放（未实现）
- [x] 基本的单词学习界面

第二阶段：
- [ ] 分享功能
  - [x] 基础 UI 实现
  - [ ] 分享内容模板
  - [ ] 分享图片生成
- [x] 词根词缀的完整目录
- [ ] 数据同步机制

后续阶段：
- [ ] 用户自定义单词组功能
- [ ] 性能优化
- [ ] 用户体验改进

## 安装说明
1. 克隆项目
2. 打开 .xcodeproj 文件
3. 编译运行

## License
MIT License

### 10. 数据库结构
lexitree.db 包含以下表：
1. words（单词表）
   - id: UUID
   - text: 单词
   - meaning: 中文含义
   - root: 词根
   - prefix: 前缀（可选）
   - suffix: 后缀（可选）
   - pronunciation: 发音

2. roots（词根表）
   - id: UUID
   - text: 词根
   - meaning: 中文含义
   - description: 详细描述

3. affixes（词缀表）
   - id: UUID
   - text: 词缀
   - type: 类型（前缀/后缀）
   - meaning: 中文含义

4. sentences（例句表）
   - id: UUID
   - word_id: TEXT (外键关联 words 表)
   - text: TEXT (英文例句)
   - translation: TEXT (中文翻译)
   - created_at: DATETIME (创建时间)

5. root_relations（词根关系表）
   - id: UUID
   - root1_id: TEXT (外键关联 roots 表)
   - root2_id: TEXT (外键关联 roots 表)
   - relation_type: TEXT (关系类型，如：同源、相近等)
   - description: TEXT (关系描述)
   - created_at: DATETIME (创建时间)

6. learning_records（学习记录表）
   - id: UUID
   - date: DATE (学习日期)
   - minutes: INTEGER (学习时长)
   - created_at: DATETIME (创建时间)

### 数据模型
1. Word
   - 遵循协议：Identifiable, Codable, Hashable
   - 属性：
     - id: UUID
     - text: String
     - meaning: String
     - root: String
     - prefix: String?
     - suffix: String?
     - pronunciation: String

2. Root
   - 遵循协议：Identifiable, Codable
   - 属性：
     - id: UUID
     - text: String
     - meaning: String
     - rootDescription: String

3. Affix
   - 遵循协议：Identifiable, Codable
   - 属性：
     - id: UUID
     - text: String
     - type: AffixType
     - meaning: String