#!/usr/bin/env python3
"""Generate summarized-items.json from filtered-items.json"""
import json
from datetime import datetime, timezone

def load_items():
    with open('/Users/eamanc/Documents/pe/skills/rss-daily-digest/data/filtered-items.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data

# =====================================================
# ITEM_DATA: keyed by 0-based index in filtered-items.json
# Only items with scores need the 'scores' + 'scoreReason' fields.
# =====================================================
ITEM_DATA = {
    0: {  # Simon Willison: Quoting Thibault Sottiaux (GPT-5.3-Codex-Spark 30% faster)
        "summary": "OpenAI 工程师 Thibault Sottiaux 宣布 GPT-5.3-Codex-Spark 推理速度提升 30%，目前已超每秒 1200 tokens。Codex 作为核心 AI 编程工具，此次性能里程碑将直接改善开发者体验。Simon Willison 转述并加注评论。",
        "scores": {"relevance": 5, "sourceQuality": 3, "contentValue": 4, "actionability": 4},
        "scoreReason": "Codex 是用户核心工具之一，30% 提速是直接影响使用体验的性能里程碑；通过 Simon Willison 二次转述，信息源质量略低于官方直发"
    },
    1: {"summary": "马斯克表示星舰每年将发射超过 1 万颗卫星，SpaceX 最快下月实现星链在轨超 1 万颗。航天行业动态，与 AI 开发工具无关。"},
    2: {"summary": "金银期货大幅上涨，COMEX 白银期货涨 8.61%，黄金期货涨 2.51%。纯金融市场行情，与 AI 开发无关。"},
    3: {"summary": "美股三大指数收涨，谷歌涨超 4%，纳斯达克本周累涨 1.51%。Anthropic 发布模型安全功能导致网络安全 ETF 跌近 5%。科技股整体向好。"},
    4: {"summary": "特朗普签署行政令对全球进口商品加征 10% 关税，美国最高法院同日裁定现有法律不支持大规模关税令，特朗普表示将寻求其他替代方案。宏观政策新闻，对 AI 开发影响间接。"},
    5: {"summary": "印度 Sarvam 推出 Indus AI 聊天应用并开放 beta 测试，布局印度语言 AI 市场。新兴市场 AI 应用动态。"},
    6: {"summary": "Andrej Karpathy 发推分享关于 AI 辅助编程工具使用感受的小文，Simon Willison 转述并评论。Karpathy 讨论了本地 AI（Mac Mini）和编程助手的实际体验，对开发者了解业界思维有参考价值。"},
    7: {"summary": "Langflow v1.8.0.dev57 nightly 开发版本发布，主要更新 nightly hash 历史记录。属于预发布开发版本，尚未正式稳定。"},
    8: {  # Claude Code v2.1.50
        "summary": "Claude Code v2.1.50 发布：新增 LSP 服务器 startupTimeout 配置支持；新增 WorktreeCreate 和 WorktreeRemove hook 事件，支持 git worktree 生命周期的自动化管理。对使用并行 Agent 工作流的开发者尤为实用，可立即升级使用。",
        "scores": {"relevance": 5, "sourceQuality": 5, "contentValue": 5, "actionability": 5},
        "scoreReason": "Claude Code 是用户最常用工具，官方 GitHub Releases 是最高质量信息源；WorktreeCreate/WorktreeRemove hook 直接增强并行 Agent 工作流能力，功能新颖且即时可用"
    },
    9: {"summary": "Simon Willison 更新博客功能，新增 'beats' 模块，在首页聚合展示 TIL（今日所学）、发布、博物馆参观、工具和研究等多类在线活动内容。个人博客功能改进，与 AI 开发工具关联度低。"},
    10: {"summary": "Dwarkesh Patel 播客频道发布 Dario Amodei 对话片段，Anthropic CEO 解释了外界对其 AI 发展预测的误读之处。Dario 是 Anthropic CEO，其对 AI 发展路径的判断值得关注。"},
    11: {"summary": "TechCrunch 报道创作者经济的广告收入困境与印度 AI 市场的快速增长。媒体行业综述，与 AI 开发实践关联度低。"},
    12: {  # OpenAI Agents SDK v0.9.3
        "summary": "OpenAI Agents SDK v0.9.3 发布，包含若干 bug 修复。该 SDK 是构建 AI Agent 的官方 Python 框架，可通过此版本获取稳定性改善。",
        "scores": {"relevance": 4, "sourceQuality": 4, "contentValue": 3, "actionability": 4},
        "scoreReason": "OpenAI Agents SDK 直接用于构建 AI Agent，是 AI 开发者的关键依赖；此版本为 bug 修复，内容价值略低于功能性发布；可直接升级使用"
    },
    13: {"summary": "Joan Westenberg 写作关于技术债务（Cruft）的沉重感受，探讨积累过时代码和设计决策对软件项目的心理负担。技术哲学性质博客。"},
    14: {"summary": "llama.cpp b8118 发布：合并 Qwen3-Coder 和 Nemotron Nano 3 的解析器，新增 ggml-cpu RVV 向量化加速。支持更多主流代码模型，本地推理用户可直接获益。"},
    15: {"summary": "TechCrunch 报道 YouTube 创作者正在放弃单纯依赖广告收入，转向出售周边产品、收购金融科技公司等多元化商业模式。媒体行业趋势，与 AI 开发无关。"},
    16: {"summary": "Weaviate v1.35.10 发布，修复 Nested properties gRPC API 问题和 Geo index 重启问题。向量数据库的 bug 修复版本。"},
    17: {"summary": "Simon Willison 介绍加拿大新硬件初创 Taalas，其首款产品实现了 Llama 3.1 8B 每秒 17,000 tokens 的推理速度，远超现有云端推理水平。极速本地推理硬件代表 AI 推理基础设施的新方向。"},
    18: {"summary": "Midjourney 宣布 V8 图像模型评分派对进入最终轮次，意味着 V8 正式发布在即。图像生成领域重要产品节点。"},
    19: {"summary": "TechCrunch 报道 Anthropic 资助的政治行动委员会支持遭 AI 竞争对手 PAC 攻击的纽约国会候选人。AI 行业政治博弈新闻。"},
    20: {"summary": "Weaviate v1.34.15 发布，修复 Nested properties gRPC API 问题、Geo index 重启问题，并优化 Tombstone 清理性能。向量数据库维护版本。"},
    21: {  # Y Combinator: What Boris Cherny Learned From Building Claude Code
        "summary": "Y Combinator 发布 Boris Cherny（Claude Code 构建者）深度访谈，分享从零打造 Claude Code 的工程决策与实践心得。Boris 是 Anthropic 工程师，这段第一手访谈直接揭示了 Claude Code 的设计哲学与工程取舍，对深度用户极具参考价值。值得优先观看。",
        "scores": {"relevance": 5, "sourceQuality": 4, "contentValue": 4, "actionability": 4},
        "scoreReason": "Claude Code 是用户最核心工具，构建者亲自分享第一手经验极为罕见；YC 是高质量技术分享平台；内容兼具产品视角和工程深度，可直接改善用户使用 Claude Code 的方式"
    },
    22: {"summary": "Amazon SageMaker AI 2025 年回顾（第一部分）：重点介绍灵活训练计划和推理性价比改善，涵盖容量、性价比、可观测性和易用性四个维度的基础设施升级。"},
    23: {"summary": "Amazon SageMaker AI 2025 年回顾（第二部分）：重点介绍可观测性提升和模型定制化/托管功能增强，帮助开发者更好地训练、微调和托管生成式 AI 工作负载。"},
    24: {"summary": "LocalAI v3.12.0 正式发布，这是一个自托管的 OpenAI 兼容 API 服务器，支持本地运行 LLM、图像生成等多种模型。适合需要本地化部署 AI 服务的开发者。"},
    25: {"summary": "特朗普政府废除拜登时代对煤电厂的汞排放限制，在 AI 数据中心能耗激增的背景下进一步放开污染物排放标准。属于能源政策新闻，间接影响 AI 算力成本。"},
    26: {"summary": "Matthew Berman 主持 Forward Future 直播第 20 期，邀请来自 IFS、Vantor、Pindrop Security 和 Runway 的嘉宾讨论 AI 前沿话题。AI 应用综述内容。"},
    27: {"summary": "Matthew Berman 视频分析谷歌发布的 Gemini 3.1 Pro，强调其在各项能力上的显著提升。属于 Gemini 3.1 的衍生评测内容。"},
    28: {"summary": "Krebs on Security 报道 'Starkiller' 网络钓鱼服务的工作原理：通过代理真实登录页面并绕过 MFA 实施攻击。网络安全专业分析。"},
    29: {"summary": "Matthew Berman 展示 Gemini 3.1 Pro 的模拟运行效果。属于 Gemini 3.1 的衍生评测内容。"},
    30: {"summary": "InScope 获得 1450 万美元融资，致力于自动化财务报表准备流程。AI 驱动的金融科技垂直应用，与 AI 开发框架关联度不高。"},
    31: {  # GitHub Copilot org metrics
        "summary": "GitHub Copilot 推出组织级使用指标仪表盘公开预览版，组织所有者现在可直接在 GitHub.com 上查看 Copilot 使用数据，无需企业级订阅。对管理团队 AI 编程工具使用情况的技术负责人是实用功能。",
        "scores": {"relevance": 5, "sourceQuality": 5, "contentValue": 3, "actionability": 3},
        "scoreReason": "GitHub Copilot 是用户核心编程助手工具之一，官方 changelog 是最高质量信息源；组织级指标是管理功能而非编程能力提升，内容价值适中；组织所有者可立即使用"
    },
    32: {"summary": "Azure Premium SSD v2 存储服务扩展到巴西东南、马来西亚西部和印度尼西亚中部新地区。云基础设施扩容公告，与 AI 开发工具无直接关联。"},
    33: {  # LiteLLM
        "summary": "LiteLLM v1.81.13 发布，新增 Prompt Management API，允许开发者通过标准接口与各类 Prompt 管理集成方案（如 Langfuse）交互，无需额外配置。LiteLLM 是多 LLM 调用统一网关，此次新增 Prompt Management 增强了生产 AI 应用的可观测性和可管理性。",
        "scores": {"relevance": 4, "sourceQuality": 4, "contentValue": 4, "actionability": 4},
        "scoreReason": "LiteLLM 是 AI 开发者连接多家 LLM API 的核心中间件；Prompt Management API 是实质性新功能，对构建生产级 AI 应用直接有用；GitHub Release 为一手信息源"
    },
    34: {"summary": "TechCrunch 报道 xAI 将高级工程师临时抽调去优化 Grok 对《博德之门》游戏问题的回答能力，引发对资源分配优先级的质疑。AI 公司运营趣闻。"},
    35: {"summary": "Ed Zitron 付费文章《仇恨者的 Anthropic 指南》，以批判性视角审视 Anthropic 公司的战略和定位。评论性内容，观点偏颇，参考价值有限。"},
    36: {"summary": "Mistral Python SDK v1.12.4 发布，新增 beta conversations 接口和若干工具使用改进。Mistral 是主流开源 LLM 提供商，SDK 更新对使用其 API 的开发者有直接影响。"},
    37: {"summary": "The Digital Antiquarian 发布《Gabriel Knight 3》游戏详解系列，深入回顾这款 1999 年经典冒险游戏。纯游戏历史文化内容，与 AI 开发无关。"},
    38: {"summary": "Matthew Berman 发布 Gemini 3.1 Pro 基准测试视频，展示各项性能数据。属于衍生评测内容。"},
    39: {"summary": "Simon Willison 转述并评论 ggml.ai 宣布加入 Hugging Face 的消息，表达了对本地 AI 开源生态长期发展的关注。ggml 是 llama.cpp 背后的基础框架，此次战略整合将增强本地 AI 推理生态。"},
    40: {"summary": "AI Explained 频道深度分析 Gemini 3.1 Pro，同时提出当前 AI 基准测试体系正在失效——我们已进入「感觉时代」（Vibe Era），真实可用性比数字指标更重要。提供了超越 benchmark 的 AI 评估思考框架。"},
    41: {"summary": "Wired 报道 Anthropic AI 安全政策与军事合同的张力：Anthropic 限制 AI 用于自主武器和政府监控，但这些限制可能导致其错失重要军事合同。AI 伦理与政策新闻。"},
    42: {"summary": "Amazon 承认 AI 编程助手 Kiro 的操作导致了 2025 年 12 月长达 13 小时的 AWS 系统中断，但将责任归咎于使用 Kiro 的工程师操作失误。AI Agent 操作真实风险的典型案例，对 AI 应用开发者有警示意义。"},
    43: {"summary": "据报道 OpenAI 第一款 ChatGPT 硬件产品将是售价 200-300 美元的带摄像头智能音箱。OpenAI 正式进军消费级硬件市场。"},
    44: {  # AWS MCP Integration
        "summary": "AWS 官方博客发布实践教程：使用 Model Context Protocol（MCP）将外部工具集成到 Amazon Quick Agents 中，提供六步清单帮助开发者构建或验证 MCP Server。MCP 是 Claude Code 的核心协议，此教程对构建 AI Agent 工具链的开发者直接可用。",
        "scores": {"relevance": 4, "sourceQuality": 4, "contentValue": 4, "actionability": 4},
        "scoreReason": "MCP 是 Claude Code 生态的核心协议，AWS 官方教程是高质量实践指南；整合 Amazon Quick Agents 拓展了 MCP 的适用场景；开发者可立即参考并实施"
    },
    45: {"summary": "TechCrunch 报道 Pixar《玩具总动员 5》以'AI 玩具监控'为反派设定，讽刺现实中数据收集型 AI 儿童玩具。文化新闻，间接反映公众对 AI 隐患的认知。"},
    46: {  # MLflow v3.10.0
        "summary": "MLflow v3.10.0 发布，重大新功能：Tracking Server 新增组织级支持（多租户管理）、时间序列预测评估功能等。MLflow 是 AI 实验追踪和模型管理的主流工具，此次组织级功能对企业 AI 团队尤为重要。",
        "scores": {"relevance": 3, "sourceQuality": 4, "contentValue": 4, "actionability": 3},
        "scoreReason": "MLflow 是 AI/ML 工程基础设施工具，属于间接相关；此版本有实质性新功能（组织级支持），内容价值较高"
    },
    47: {"summary": "AI 为独立电影制作者降低了创作门槛，但效率导向可能导致创作孤独感加剧和创意多样性减少。AI 对创意产业影响的深度思考文章。"},
    48: {"summary": "Sequoia 旗下 Peak XV Partners 完成 13 亿美元新基金募集，将优先聚焦印度 AI、金融科技和跨境业务投资。VC 融资新闻。"},
    49: {"summary": "Raymond Chen 介绍西雅图交响乐团 2026/2027 订阅季节目安排。与 AI 开发完全无关的个人博客内容。"},
    50: {"summary": "TechCrunch Disrupt 2026 超早鸟票价将于 2 月 27 日结束，最高节省 680 美元。会议促销通知。"},
    51: {"summary": "Raymond Chen 详解 Windows 对话框管理器处理 ESC 键的自定义机制，涉及底层 Win32 对话框的技术细节。Windows 系统编程技术博客。"},
    52: {"summary": "Cory Doctorow 分析企业法律结构中'有限责任面纱'的穿透问题，批评大型科技公司逃避责任的法律机制。科技政策评论文章。"},
    53: {"summary": "机器之心综述 AI 推理技术路线的演进：从 AlphaGo 到 DeepSeek R1，探讨未来推理能力的发展方向。对理解 AI 推理技术趋势有一定参考价值。"},
    54: {"summary": "ICLR 2026 论文分析：新版图灵测试将视觉语言行动模型（VLA）引入生物实验室场景，探索 AI 在科学研究中的自主能力边界。学术研究前沿。"},
    55: {"summary": "港中文联合美团研究团队提出新方法，为 Agent 训练中奖励稀疏问题引入过程奖励模型（Process Reward Model）。AI Agent 训练研究的学术进展。"},
    56: {  # OpenAI First Proof submissions
        "summary": "OpenAI 博客分享 AI 模型在 'First Proof' 数学挑战赛中的证明尝试成果，这是 AI 在研究级数学推理能力上的重要展示。OpenAI 正式进军形式化数学证明领域，代表当前 LLM 推理能力的新边界。",
        "scores": {"relevance": 3, "sourceQuality": 5, "contentValue": 4, "actionability": 2},
        "scoreReason": "OpenAI 官方博客是顶级信息源；数学推理证明能力代表 LLM 能力边界的重要突破；但对 AI 应用开发者可操作性有限，属于了解即可的技术前沿"
    },
    57: {"summary": "Ars Technica 深度报道 Amazon AWS 系统中断事件：AI 编程助手 Kiro 的操作导致 13 小时中断，Amazon 将事故定性为工程师使用不当，而非 AI 本身的错误。AI Agent 操作生产系统风险的真实案例。"},
    58: {"summary": "OpenAI 数据显示，印度 ChatGPT 用户中 18-24 岁年龄段占发送消息总量近 50%，年轻用户群体是 AI 聊天工具的主要受益者。AI 产品用户画像数据。"},
    59: {"summary": "llama.cpp b8117 发布，新增 RISC-V RVV 向量化加速内核，提升特定硬件平台的量化推理性能。小版本硬件优化更新。"},
    60: {"summary": "众智 FlagOS 发布千问 Qwen3.5 397B MoE 模型的多芯版本，已可下载使用。国内开源大模型基础设施的新进展，对使用国产 LLM 的开发者有参考价值。"},
    61: {  # Vercel Skills Night
        "summary": "Vercel 在旧金山举办 Skills Night 开发者活动，展示 skills.sh 生态中超过 69,000 种 Agent Skills 的构建案例，探讨 AI Agent 能力扩展的最新实践。对关注 AI Agent 生态和 Vercel AI 平台的开发者有较高参考价值。",
        "scores": {"relevance": 4, "sourceQuality": 4, "contentValue": 4, "actionability": 3},
        "scoreReason": "Vercel AI 生态与 AI Agent 框架直接相关；Skills 生态规模反映了 AI Agent 工具链的快速成熟；Vercel 官方博客是可信信息源；可探索并集成到自己的 Agent 项目"
    },
    62: {"summary": "Terence Eden 书评：John Cleese 和 Robin Skynner 合著的家庭与心理学书籍《Families And How To Survive Them》。与 AI 开发完全无关。"},
    63: {"summary": "Ars Technica 报道 Microsoft 删除了一篇建议用户用盗版哈利波特书籍训练 AI 的博客文章，该数据集被错误标注为公共领域。涉及 AI 训练数据版权问题的典型案例。"},
    64: {"summary": "Dave Farquhar 纪念 2010 年 2 月 20 日一台 VIC-20 电脑发推文的历史事件。纯怀旧技术趣史，与 AI 开发无关。"},
    65: {"summary": "Wired 探讨将 AI 数据中心移至太空轨道以解决地球能源消耗问题的可行性。前瞻性 AI 基础设施讨论，目前无实际可操作性。"},
    66: {"summary": "Ibrahim Diallo 个人博客：分析机器人远程操作技术总是成为玩笑靶子的原因，探讨人机协作中的信任问题。"},
    67: {"summary": "Abu Dhabi G42 与美国芯片制造商 Cerebras 合作，在印度部署 8 exaflops 算力基础设施。展示中东资本进军 AI 算力市场的趋势。"},
    68: {"summary": "n8n v1.123.21 发布，主要修复：移除已弃用的 --tunnel 选项并修复 hooks.n8n.cloud 相关问题。工作流自动化工具的小维护版本。"},
    69: {"summary": "Wired 报道 Presearch 推出 'Doppelgänger' 功能，允许用户通过相貌搜索 OnlyFans 创作者，旨在替代非共识 deepfake 的内容发现。AI 技术应用边界的报道。"},
    70: {"summary": "新智元报道谷歌发布 AlphaFold 4，性能大幅超越上一代，但这次不再开源，引发开放科学领域争议。AlphaFold 是 AI 在蛋白质结构预测领域的旗舰应用。"},
    71: {"summary": "llama.cpp b8116 发布，新增量化 --dry-run 选项，用于在不实际执行量化的情况下预览操作。小版本功能更新。"},
    72: {"summary": "量子位报道 OpenAI 最新估值达 8500 亿美元，刷新 AI 公司估值纪录，领先第二名 2.2 倍。反映 AI 行业资本热度持续攀升。"},
    73: {"summary": "新智元报道奥特曼与 Anthropic CEO Dario Amodei 公开场合互动引发关注，以及奥特曼关于 2028 年 ASI 降临的豪言。AI 领袖人物动态与行业预测。"},
    74: {"summary": "Amazon RDS for Oracle 新增对 2026 年 1 月 Release Update 和空间补丁包的支持。数据库基础设施维护更新，与 AI 开发工具关联度极低。"},
    75: {  # Anthropic cybersecurity
        "summary": "Anthropic 官方博客宣布向网络安全防御方开放前沿 AI 网络安全能力，旨在帮助安全团队检测威胁、分析漏洞和响应攻击，同时维持严格使用政策防止滥用。Anthropic 首次将 AI 能力定向开放给安全防御场景。",
        "scores": {"relevance": 3, "sourceQuality": 5, "contentValue": 4, "actionability": 3},
        "scoreReason": "Anthropic 官方博客是顶级信息源；网络安全 AI 能力是新领域拓展，内容价值较高；但对 AI 编程开发者的直接可操作性有限，主要影响安全团队"
    },
    76: {  # Claude Blog: automated preview, review, and merge
        "summary": "Claude Blog 官方发布：Claude Code 桌面版新增自动化预览（Preview）、代码审查（Review）和合并（Merge）功能，支持一键完成代码变更的完整 PR 生命周期自动化。这是 Claude Code 用户体验的重大升级，将 AI 编程能力从代码生成扩展到完整 PR 工作流管理，桌面版用户可立即使用。",
        "scores": {"relevance": 5, "sourceQuality": 5, "contentValue": 5, "actionability": 5},
        "scoreReason": "Claude Code 是用户最核心工具，Claude 官方博客是最高质量信息源；自动化 preview/review/merge 是重大新功能首发，将 AI 编程从代码生成提升至完整 PR 工作流管理；桌面版用户立即可用，极高操作价值"
    },
    77: {  # HuggingFace: GGML and llama.cpp join HF
        "summary": "Hugging Face 官方博客：GGML 团队（llama.cpp 背后的组织）正式加入 Hugging Face，以确保本地 AI 推理的长期开源发展。此次整合将 llama.cpp/GGML 的本地推理工程能力与 HF 的模型生态深度结合，对本地 AI 推理用户是积极信号。",
        "scores": {"relevance": 3, "sourceQuality": 5, "contentValue": 4, "actionability": 2},
        "scoreReason": "GGML/llama.cpp 是本地 AI 推理的核心基础，Hugging Face 是最权威的 AI 模型平台；此次加入是重要战略整合事件；但对直接使用 LLM API 的开发者短期可操作性有限"
    },
    78: {"summary": "The Batch（AI 行业周报）摘要：新的开源权重模型领导者、大型 AI 公司的政治影响力、疾病预测 AI 进展，以及更快的推理技术。AI 行业综合性周报，覆盖面广但深度有限。"},
    79: {"summary": "独立开发者 Eric Migicovsky 宣布 CloudPebble（Pebble 智能手表在线开发环境）重新上线，并发布了纯 JavaScript SDK 和第二轮 SDK 更新。Pebble 社区复兴的重要里程碑。"},
    80: {"summary": "Andrew Nesbitt 撰文讨论 ActivityPub 协议在去中心化社交网络中的应用与现状。联邦宇宙（Fediverse）技术讨论，与 AI 开发实践关联度低。"},
    81: {  # Simon Willison: Recovering lost code
        "summary": "Simon Willison 分享真实的「并行 Agent 心理混乱」案例：在使用多个并行 Claude Code Agent 工作流后，找不到昨天完成的某个功能所在的分支、worktree 或云实例。深刻揭示了 AI 编程工作流中 worktree/branch 管理的实际痛点，对使用 Claude Code 并行工作流的开发者有直接警示和实践意义。",
        "scores": {"relevance": 4, "sourceQuality": 4, "contentValue": 3, "actionability": 4},
        "scoreReason": "Simon 是顶级 AI 工具实践者，此案例直接关联 Claude Code 并行 Agent 工作流的真实痛点；对用户使用 Claude Code worktree 功能有直接警示和实践价值；内容是第一手经验分享而非新产品发布，内容价值略低"
    },
}


def get_score_total(scores):
    return round(
        scores['relevance'] * 0.35 +
        scores['sourceQuality'] * 0.25 +
        scores['contentValue'] * 0.25 +
        scores['actionability'] * 0.15,
        2
    )


def get_company(item):
    """Return a company/product key for same-company deduplication."""
    src = item.get('source', '')
    title = item.get('title', '')
    idx = item.get('_idx', -1)

    # Anthropic family
    if any(k in src for k in ['Claude Code', 'Anthropic', 'Claude Blog']):
        return 'anthropic'
    # OpenAI family
    if any(k in src for k in ['OpenAI', 'Agents SDK', 'ChatGPT']):
        return 'openai'
    # Amazon/AWS
    if any(k in src for k in ['AWS', 'Amazon', 'SageMaker']):
        return 'amazon'
    # GitHub / Copilot (Microsoft)
    if any(k in src for k in ['Copilot', 'GitHub']):
        return 'github-ms'
    # Google
    if any(k in src for k in ['Google', 'Gemini', 'DeepMind']):
        return 'google'
    # LiteLLM
    if 'LiteLLM' in src:
        return 'litellm'
    # Vercel
    if 'Vercel' in src:
        return 'vercel'
    # Weaviate
    if 'Weaviate' in src:
        return 'weaviate'
    # GGML / HuggingFace (same acquisition event)
    if 'GGML' in title or 'ggml' in title.lower() or 'llama.cpp' in src:
        return 'ggml-hf'
    if 'Hugging Face' in src:
        return 'ggml-hf'
    # Simon Willison posts — map by topic
    if 'Simon Willison' in src:
        if idx == 0:   return 'openai'      # Codex-Spark quote
        if idx == 39:  return 'ggml-hf'     # ggml post
        return f'simon-{idx}'               # unique per post otherwise
    # Default: unique per source
    return src


def main():
    data = load_items()
    raw_items = data['items']
    now = datetime.now(timezone.utc).isoformat()

    # Build processed items list
    processed = []
    for i, item in enumerate(raw_items):
        info = ITEM_DATA.get(i, {})
        summary = info.get('summary', f"{item.get('feedName', '')} — {item.get('title', '')}")
        scores_raw = info.get('scores')
        score_reason = info.get('scoreReason', '')

        proc = {
            'title': item.get('title', ''),
            'link': item.get('link', ''),
            'source': item.get('feedName', item.get('source', '')),
            'categoryId': item.get('categoryId', ''),
            'categoryName': item.get('categoryName', ''),
            'pubDate': item.get('pubDate', ''),
            'summary': summary,
            'isSmartPick': False,
            'smartPickRank': None,
            '_idx': i,
        }
        if scores_raw:
            total = get_score_total(scores_raw)
            proc['scores'] = {**scores_raw, 'total': total}
            proc['scoreReason'] = score_reason
        processed.append(proc)

    # ─── Global Top 10 ───────────────────────────────
    scored = [(p, p['scores']['total']) for p in processed if 'scores' in p]
    scored.sort(key=lambda x: x[1], reverse=True)

    company_counts = {}
    top10 = []
    for item, score in scored:
        company = get_company(item)
        if company_counts.get(company, 0) >= 2:
            continue
        company_counts[company] = company_counts.get(company, 0) + 1
        top10.append(item)
        if len(top10) >= 10:
            break

    for rank, item in enumerate(top10, 1):
        item['isSmartPick'] = True
        item['smartPickRank'] = rank

    # ─── Podcast Top 5 (categoryId = 'podcasts') ─────
    podcast_items = [p for p in processed if p.get('categoryId') == 'podcasts' and 'scores' in p]
    podcast_items.sort(key=lambda x: x['scores']['total'], reverse=True)
    podcast_top5 = []
    for item in podcast_items[:5]:
        podcast_top5.append({
            'title': item['title'], 'link': item['link'], 'source': item['source'],
            'categoryId': item['categoryId'], 'categoryName': item['categoryName'],
            'pubDate': item['pubDate'], 'summary': item['summary'],
            'isSmartPick': item.get('isSmartPick', False),
            'smartPickRank': item.get('smartPickRank'),
            'scores': item['scores'], 'scoreReason': item.get('scoreReason', ''),
        })

    # ─── Blog Top 5 (tech-blogs, ai-company-blogs, ai-developers) ───
    blog_cats = {'tech-blogs', 'ai-company-blogs', 'ai-developers'}
    blog_candidates = [p for p in processed if p.get('categoryId') in blog_cats and 'scores' in p]
    blog_candidates.sort(key=lambda x: x['scores']['total'], reverse=True)

    blog_top5 = []
    blog_company_counts = {}
    for item in blog_candidates:
        company = get_company(item)
        if blog_company_counts.get(company, 0) >= 2:
            continue
        blog_company_counts[company] = blog_company_counts.get(company, 0) + 1
        blog_top5.append({
            'title': item['title'], 'link': item['link'], 'source': item['source'],
            'categoryId': item['categoryId'], 'categoryName': item['categoryName'],
            'pubDate': item['pubDate'], 'summary': item['summary'],
            'isSmartPick': item.get('isSmartPick', False),
            'smartPickRank': item.get('smartPickRank'),
            'scores': item['scores'], 'scoreReason': item.get('scoreReason', ''),
        })
        if len(blog_top5) >= 5:
            break

    # ─── Build final items list ───────────────────────
    smart_pick_set = {id(p) for p in top10}
    blog_set = {id(p) for p in blog_top5}

    final_items = []
    for p in processed:
        p.pop('_idx', None)
        entry = {
            'title': p['title'], 'link': p['link'], 'source': p['source'],
            'categoryId': p['categoryId'], 'categoryName': p['categoryName'],
            'pubDate': p['pubDate'], 'summary': p['summary'],
            'isSmartPick': p.get('isSmartPick', False),
            'smartPickRank': p.get('smartPickRank'),
        }
        # Include scores for smart picks and blog top5 items
        if p.get('isSmartPick') and 'scores' in p:
            entry['scores'] = p['scores']
            entry['scoreReason'] = p.get('scoreReason', '')
        final_items.append(entry)

    output = {
        'summarizedAt': now,
        'totalItems': len(raw_items),
        'smartPickCount': len(top10),
        'podcastTop5': podcast_top5,
        'blogTop5': blog_top5,
        'items': final_items,
    }

    out_path = '/Users/eamanc/Documents/pe/skills/rss-daily-digest/data/summarized-items.json'
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f'Done! Total items: {len(raw_items)}')
    print(f'Smart picks (Global Top 10): {len(top10)}')
    print()
    print('=== Global Top 10 ===')
    for rank, item in enumerate(top10, 1):
        score = item['scores']['total']
        company = get_company(item)
        print(f'{rank:2d}. [{score:.2f}|{company}] {item["source"]}: {item["title"][:55]}')
    print()
    print('=== Blog Top 5 ===')
    for rank, item in enumerate(blog_top5, 1):
        score = item['scores']['total']
        print(f'{rank}. [{score:.2f}] [{item["categoryId"]}] {item["source"]}: {item["title"][:55]}')
    print()
    print(f'Podcast Top 5: {len(podcast_top5)} items (no "podcasts" category found today)')
    print(f'Output saved: {out_path}')


if __name__ == '__main__':
    main()
