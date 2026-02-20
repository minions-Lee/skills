# 快速设置指南

## 当前服务器已完成

✅ GitHub CLI 2.86.0 已安装
✅ Git 仓库已初始化
✅ GitHub 目录已创建: `~/github`

## 下一步：认证 GitHub

运行以下命令完成认证：

```bash
gh auth login
```

按照提示操作：
1. 选择 `GitHub.com`
2. 选择 `HTTPS` 协议
3. 选择 `Yes` 登录
4. 按回车使用浏览器登录，或选择粘贴 token

## 推送到 GitHub

1. 在 GitHub 创建新仓库（例如：`github-kb`）

2. 添加远程仓库并推送：
```bash
git remote add origin https://github.com/goodniuniu/github-kb.git
git branch -M main
git push -u origin main
```

## 在其他服务器使用

```bash
# 1. Clone 项目
git clone https://github.com/goodniuniu/github-kb.git
cd github-kb

# 2. 安装 gh CLI（如果未安装）
bash skills/github-kb/install-gh.sh

# 3. 认证
gh auth login

# 4. 开始使用！
# 直接在项目目录下打开 Claude Code 并提问
```

## 使用示例

### 克隆仓库
```
Please clone the anthropic/claude-code repository
```

### 搜索 GitHub
```
Search GitHub for "AI coding agent"
```

### 查看项目列表
```
What projects do I have?
```

## 项目信息

- **作者**: goodniuniu
- **目录**: `~/github`
- **技能文档**: `skills/github-kb/SKILL.md`
- **项目目录**: `CLAUDE.md`
