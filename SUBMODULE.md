# Git Submodule 操作手册

## 首次 clone 主仓库（含所有子模块）

```bash
git clone --recurse-submodules git@github.com:minions-Lee/skills.git
```

已有仓库但子模块目录为空：

```bash
git submodule update --init --recursive
```

---

## 拉取子模块最新代码

### 更新全部子模块

```bash
git submodule update --remote --merge
git add .
git commit -m "chore: 更新所有子模块到最新版本"
git push
```

### 更新单个子模块

```bash
cd ai-dev-standards
git pull origin main
cd ..
git add ai-dev-standards
git commit -m "chore: 更新 ai-dev-standards 子模块"
git push
```

---

## 添加新的子模块

```bash
git submodule add -b main <仓库URL> <目录名>
git commit -m "chore: 添加子模块 <目录名>"
git push
```

---

## 删除子模块

```bash
# 1. 取消注册
git submodule deinit -f <目录名>

# 2. 删除 .git/modules 中的缓存
rm -rf .git/modules/<目录名>

# 3. 删除目录并从暂存区移除
git rm -f <目录名>

# 4. 提交
git commit -m "chore: 移除子模块 <目录名>"
```

---

## 切换子模块到指定 commit/tag

```bash
cd <目录名>
git checkout <commit-hash 或 tag>
cd ..
git add <目录名>
git commit -m "chore: 锁定 <目录名> 到指定版本"
```

---

## 查看子模块状态

```bash
# 查看所有子模块当前指向的 commit
git submodule status

# 查看子模块是否有变更
git diff --submodule
```

---

## 待处理

- `fenxiang-skills`：GitLab 服务恢复后执行：
  ```bash
  git submodule add -b main http://gitlab.fenxianglife.com/fx-ai/fenxiang-skills.git fenxiang-skills
  git commit -m "chore: 添加 fenxiang-skills 子模块"
  ```
