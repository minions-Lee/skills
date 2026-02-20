# GitHub KB - 快速参考

## 5 分钟上手

```bash
# 1. 安装 gh CLI
bash skills/github-kb/install-gh.sh

# 2. 认证
gh auth login

# 3. 初始化知识库
bash skills/github-kb/init-repos.sh

# 4. 开始提问
# 在项目目录下用 Claude Code
```

## 常用命令

### 仓库管理

```bash
# 克隆仓库
gh repo clone <owner>/<repo>

# 更新所有仓库
cd ~/github && for d in */; do cd $d && git pull && cd ..; done

# 查看仓库大小
du -sh ~/github/*

# 搜索仓库
gh search repos <query>
```

### 提问示例

**了解项目：**
> "clawdbot 是什么项目？"

**架构分析：**
> "分析 open-interpreter 的架构设计"

**技术选型：**
> "我想做一个 AI 客服系统，推荐技术方案"

**对比分析：**
> "对比 clawdbot 和 open-interpreter 的实现方式"

**学习研究：**
> "深入研究 langchain 的 RAG 实现"

## CLAUDE.md 模板

```markdown
## 分类名称

### [repo-name](/repo-path)
项目描述
核心技术栈：技术1、技术2
适用场景：场景1、场景2
```

## 配置

**修改知识库路径：**
```bash
export GITHUB_KB_DIR=/your/path
```

**修改克隆并发数：**
编辑 `init-repos.sh`：
```bash
MAX_PARALLEL=5
```

## 故障排除

| 问题 | 解决方案 |
|------|----------|
| gh 找不到 | `bash skills/github-kb/install-gh.sh` |
| 认证失败 | `gh auth logout && gh auth login` |
| 克隆超时 | 检查网络或增加 `CLONE_TIMEOUT` |
| 磁盘不足 | 使用 `--depth 1` 或删除旧仓库 |

## 项目结构

```
github-kb/
├── USER_GUIDE.md      # 完整使用手册
├── SETUP.md           # 快速设置
├── CLAUDE.md          # 知识库目录
└── skills/
    └── github-kb/
        ├── SKILL.md          # 技能说明
        ├── init-repos.sh     # 初始化脚本
        └── install-gh.sh     # 安装脚本
```

## 更多帮助

- **完整手册**：`USER_GUIDE.md`
- **优化说明**：`skills/github-kb/OPTIMIZATION.md`
- **GitHub**：https://github.com/goodniuniu/github-kb
