CREATE DATABASE IF NOT EXISTS plant_diary_db DEFAULT CHARSET utf8mb4;

USE plant_diary_db;

-- 1. 用户实体表（保持不变）
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '用户主键ID',
  `username` VARCHAR(50) NOT NULL UNIQUE COMMENT '登录账号',
  `password_hash` VARCHAR(255) NOT NULL COMMENT '加密后的密码',
  `memo` VARCHAR(255) DEFAULT '' COMMENT '备注信息',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户实体表';

-- 2. 新增：植物档案表（实现在线花园、记录每盆植物的最新状态）
CREATE TABLE IF NOT EXISTS `plants` (
  `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '植物主键ID',
  `user_id` INT NOT NULL COMMENT '所属用户ID',
  `name` VARCHAR(100) NOT NULL COMMENT '用户给植物起的昵称（如：小绿）',
  `species` VARCHAR(100) DEFAULT '' COMMENT 'AI识别的精确植物品种',
  `water_days` INT DEFAULT 0 COMMENT '浇水周期(天)',
  `sunlight` VARCHAR(50) DEFAULT '' COMMENT '光照建议',
  `fertilize` VARCHAR(100) DEFAULT '' COMMENT '施肥建议',
  `health_score` INT DEFAULT 100 COMMENT '最新健康评分',
  `tips` VARCHAR(255) DEFAULT '' COMMENT '核心养护建议',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='植物档案表';

-- 3. 新增：植物生长与打卡记录表（实现时光轴、历史健康病历本功能）
CREATE TABLE IF NOT EXISTS `growth_records` (
  `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '记录主键ID',
  `plant_id` INT NOT NULL COMMENT '所属植物ID',
  `record_type` VARCHAR(50) NOT NULL COMMENT '记录类型: identify(建档识别)/analyze(健康分析)/compare(对比分析)',
  `image_base64` LONGTEXT COMMENT '植物照片Base64数据（用于前端历史回显）',
  `analysis_result` TEXT COMMENT 'AI返回的文本结论或JSON字符串',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`plant_id`) REFERENCES `plants`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='植物生长与打卡记录表';

USE plant_diary_db;

-- 4. 新增：养护提醒表（实现前端的“每日养护待办闹钟”）
CREATE TABLE IF NOT EXISTS `reminders` (
  `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '提醒主键ID',
  `user_id` INT NOT NULL COMMENT '所属用户ID',
  `plant_id` INT NOT NULL COMMENT '所属植物ID',
  `task_type` VARCHAR(50) NOT NULL COMMENT '提醒类型: water(浇水)/fertilize(施肥)/prune(修剪)',
  `remind_time` DATETIME NOT NULL COMMENT '设定的提醒时间',
  `is_completed` TINYINT DEFAULT 0 COMMENT '状态: 0-未完成, 1-已完成打卡',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`plant_id`) REFERENCES `plants`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='养护提醒表';

-- 5. 新增：植物百科表（实现前端的“百科科普/搜索栏”模块）
CREATE TABLE IF NOT EXISTS `plant_encyclopedia` (
  `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '百科主键ID',
  `species_name` VARCHAR(100) NOT NULL UNIQUE COMMENT '植物学名（如：绿萝、多肉）',
  `alias` VARCHAR(100) DEFAULT '' COMMENT '别名',
  `morphology` TEXT COMMENT '形态特征描述',
  `growth_habit` TEXT COMMENT '生长习性',
  `toxicity` VARCHAR(255) DEFAULT '无毒' COMMENT '毒性说明',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='植物百科表';

-- 6. 新增：用户百科收藏关联表（典型多对多关系，体现标准关系型数据库设计）
CREATE TABLE IF NOT EXISTS `user_favorites` (
  `id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '收藏主键ID',
  `user_id` INT NOT NULL COMMENT '用户ID',
  `encyclopedia_id` INT NOT NULL COMMENT '百科文章ID',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `user_article_unique` (`user_id`, `encyclopedia_id`), -- 避免重复收藏
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`encyclopedia_id`) REFERENCES `plant_encyclopedia`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户百科收藏关联表';