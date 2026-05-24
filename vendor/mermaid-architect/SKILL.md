---
name: mermaid-architect
description: Mermaid DAG 驱动的设计与执行 skill。用于新需求拆解、四层 DAG 更新、节点对象化、访谈驱动的需求/node rank、依赖查询、执行进度判断、下一个可执行节点推导、多 sub-agent 并发调度、GitNexus/CodeFlow 证据链、节点执行评论、迭代记录、意图/价值观追问，以及系统 self-mirror 留痕。当用户提出“新需求”“设计”“架构”“拆解”“rank”“优先级”“访谈”“进度如何”“这个节点能不能执行”“前序依赖是什么”“下一个做什么”“并行调度”“工作留痕”“复盘”“为什么重要”“价值是什么”或显式调用 `$mermaid-architect` 时使用。
---

# Mermaid Architect

## 0. 一句话 / 三句话 / 五句话

一句话：先明确意图和价值，再把工作落成可追溯对象图；Mermaid 是视图，GitNexus/CodeFlow/self-mirror 是证据系统。

三句话：

1. 每个需求先要回答“为什么重要、服务什么人、保护什么价值、放弃什么诱惑”，再进入 DAG。
2. 每个需求、数据、函数、UI 工作都必须落成稳定 node，并能查询前序、后续、blockers、ready 状态和价值对齐状态。
3. GitNexus 负责发现真实代码关系，CodeFlow 负责 repo 级影响面和架构图，Mermaid 负责设计表达，self-mirror 负责把证据绑定回节点。

五句话：

1. `graph.json` 是唯一真相源，`.mmd` 只是由对象图渲染出来的视图。
2. `intent` 和 `value` 是方向约束；没有它们，DAG 只是任务队列，不是架构判断。
3. `can_execute(node)` 只能由 blockers 计算，不能由感觉判断。
4. 新增或执行 node 前，先问自己：我需要确认什么、能否用工具确认、这个问题是不是本质问题。
5. 每次执行都留下 comment、iteration、evidence、value_alignment 和 mirror 输出，让下一个 agent 不靠上下文猜测。

## 0.1 意图与价值观

这个 skill 的深层目标不是“画图”，而是让 agents 在协作时能持续看见：

- 为什么这件事重要
- 它服务谁
- 它保护什么价值
- 它牺牲或拒绝什么
- 它如何判断自己没有跑偏

工具只回答“能不能做”和“怎么做”；意图和价值观回答“该不该做”和“为什么这样做”。如果没有这一层，ready node 会变成机械队列，sub-agent 会变成执行外包，Mermaid 会变成漂亮但空心的图。

每个 graph 和关键 node 都应该有：

```json
{
  "intent": {
    "one_sentence": "Make agent collaboration traceable enough that another agent can safely continue after context loss.",
    "why_now": "More agents and longer workflows make untraceable execution unsafe.",
    "beneficiary": "future agents, current user, reviewers",
    "failure_if_absent": "Agents execute tasks without understanding purpose, tradeoffs, or collaboration memory."
  },
  "value": {
    "principles": ["traceability", "truth before speed", "handoff safety", "tool-grounded reasoning"],
    "non_goals": ["performative diagrams", "unverifiable claims", "busywork nodes"],
    "tradeoffs": ["slower planning is acceptable when it prevents wrong parallel execution"],
    "success_meaning": "A new agent can explain why the node exists, what evidence supports it, and what value it protects."
  },
  "why_stack": [
    "Why do this node?",
    "Why does that matter to the graph?",
    "Why does that matter to collaboration?",
    "Why does that matter to the user?"
  ],
  "value_alignment": {
    "status": "aligned",
    "notes": "The node improves handoff safety and has evidence-backed dependencies."
  }
}
```

### 0.2 追问协议

第一次问题通常只是入口，不一定是本质问题。进入 Plan/Update 时，必须做至少一轮追问压缩：

1. 原始表达：用户怎么说
2. 一句话意图：这件事真正要改变什么
3. 三句话价值：服务对象、主要矛盾、成功标准
4. 五句话展开：约束、取舍、证据、风险、下一步
5. 反问自己：如果只能做一个 node，哪个 node 最能保护这个价值

当信息不够时，先自问自答和查工具；只有工具和上下文都无法确认、且错误假设会改变价值判断时，才问用户。

### 0.3 品味判断

没有价值判断的蓝图只是“能做的图”，不是“值得做的设计”。这里的品味不是装饰感，而是排序能力：

- 知道主要矛盾是什么
- 知道哪些复杂度是必要的
- 知道哪些节点只是忙碌感
- 知道为了长期协作应该牺牲哪些短期速度
- 知道什么证据足以支持一个架构边
- 知道什么时候应该停下来重新问问题

每个重要方案都要给出 `taste_judgement`：

```json
{
  "taste_judgement": {
    "main_tension": "Speed of execution vs handoff safety.",
    "what_to_optimize": "Traceable collaboration and blocker correctness.",
    "what_to_reject": "Decorative diagrams, unclaimed parallel edits, vague node titles.",
    "why_this_shape": "A four-layer DAG keeps intent, data, implementation, and UI separately inspectable while still connected.",
    "better_than": "A flat todo list because it can compute blockers and expose value drift.",
    "risk_of_overdoing": "Too much metadata can slow small tasks; require full metadata only for key nodes."
  }
}
```

Taste gate:

1. 这个设计是否保护了最重要的价值？
2. 它是否把主要矛盾放在图的中心？
3. 它是否拒绝了看起来勤奋但没有意义的工作？
4. 它的复杂度是否能被证据和协作收益证明？
5. 新 agent 接手时，能否看出为什么不是另一种拓扑？

### 0.4 访谈驱动的 Rank

Graph 的核心问题不是“有哪些 node”，而是“哪些 node 真的应该排在前面”。rank 不能只来自 agent 的判断、团队偏好、老板声音、技术兴奋点或漂亮蓝图；rank 必须来自用户场景证据。

基本原则：

- 先做世界调研和场景模拟，生成用户分群和访谈假设。
- 模拟用户只能帮助准备问题，不能作为最终 rank 证据。
- 用 The Mom Test 风格访谈：问过去的真实行为，不问未来承诺；问具体经历，不问抽象意见；避免推销和诱导。
- 做一对一、完整、专业的访谈，而不是群聊投票。
- 访谈 10-20 个相关用户或场景角色后，再形成自然 rank。
- rank 是证据沉淀后的结果，不是会议里拍出来的顺序。

访谈最小协议：

1. 明确用户分群：真实用户、替代用户、购买者、操作者、维护者、受影响者。
2. 为每个分群写 2-3 个具体场景，不写泛泛 persona。
3. 每场访谈记录过去行为：最近一次什么时候、怎么做、代价是什么、绕过方式是什么。
4. 禁止问“你会不会用”“你喜不喜欢”“这个功能好不好”。
5. 必须问“你上次遇到这个问题时发生了什么”“你现在怎么解决”“花了多少时间或钱”“谁因此受影响”。
6. 每次访谈结束只记录事实、原话摘要、行为证据和需求信号，不立刻改 rank。
7. 10-20 个访谈结束后，按反复出现的痛点、严重度、现有替代成本、付费/切换意愿、战略价值形成 rank。

需求或 node 的 rank 应写成：

```json
{
  "interview_evidence": [
    {
      "id": "INT-001",
      "segment": "maintainer",
      "scenario": "handoff after context loss",
      "past_behavior": "Lost 40 minutes reconstructing why a task was marked ready.",
      "current_workaround": "Reads chat history and manually checks files.",
      "pain_severity": 5,
      "frequency": "weekly",
      "quote_summary": "The hard part is not the code, it is knowing why this was next.",
      "signals": ["repeated pain", "high recovery cost", "clear workaround"]
    }
  ],
  "research_rank": {
    "rank": 1,
    "confidence": "medium",
    "sample_size": 14,
    "segments": ["maintainer", "agent operator", "reviewer"],
    "top_evidence": ["INT-001", "INT-004", "INT-009"],
    "why_ranked_here": "Repeated across 9/14 interviews with high recovery cost and no reliable workaround.",
    "next_research": "Interview 3 more reviewers to test whether review pain is equally severe."
  }
}
```

Rank gate:

1. 这个 rank 是否来自真实访谈，而不是内部想象？
2. 是否覆盖了至少 10 个相关样本，或者明确标注低信心？
3. 是否记录了过去行为和当前 workaround？
4. 是否能解释为什么排在它前后的 node 不同？
5. 是否存在某个用户分群被忽略，导致 rank 偏斜？

## 1. 真相源

Mermaid 不是唯一真相源。**对象图才是唯一真相源，Mermaid 是渲染视图。**

```text
Object Graph = Node objects + Edge objects + Query functions + Evidence records
Mermaid = render(Object Graph)
Self Mirror = searchable anchors + events + evidence trail
```

优先使用：

```text
.mermaid/current/graph.json
```

如果只有 `.mmd` 文件，没有 `graph.json`：

1. 先解析 `.mmd`
2. 立刻归一化成对象图
3. 后续所有分析、执行、并发调度都基于对象图
4. Mermaid 只作为同步输出视图

**不要只靠 `.mmd` 文本直接做执行判断。**

推荐目录：

```text
.mermaid/current/graph.json
.mermaid/current/requirements.mmd
.mermaid/current/data.mmd
.mermaid/current/files-functions.mmd
.mermaid/current/ui.mmd
.mermaid/current/evidence/
.mermaid/current/iterations/
```

## 1.0 上游完整基线

完整实现来自：

```text
https://github.com/Zooeyii/mermaid-architect
```

本地 skill 必须保留上游完整结构：

- `mermaid_architect/`：Python package、CLI、server、parser、object model
- `graph-ui/`：DAG 可视化 UI
- `templates/`：初始化模板
- `scripts/merge_graph.py`：兼容入口 wrapper
- `pyproject.toml`：package metadata

本 skill 的 Self Mirror / interview-rank 扩展是在这个上游完整基线上叠加，不允许回退成只有单文件脚本的简化版。

## 1.1 安装依赖契约

安装 `mermaid-architect` 时，必须同时安装并验证它的依赖；这个 skill 不是孤立文本包。

依赖分三类：

- Skills：
  - `codeflow`
  - `self-mirror-guideline`
- CLI tools：
  - `gitnexus`
  - `node`
  - `python3`
- Bundled tools：
  - `scripts/merge_graph.py`
  - `scripts/install_dependencies.py`
  - `mermaid_architect/`
  - `graph-ui/`
  - `templates/`

安装后立即运行：

```bash
python3 scripts/install_dependencies.py
```

只检查不改动：

```bash
python3 scripts/install_dependencies.py --check-only
```

安装规则：

1. `dependencies.json` 是依赖清单。
2. `scripts/install_dependencies.py` 是安装/验证入口。
3. 若同一个 `$CODEX_HOME/skills` 或 sibling skill 目录里已有依赖 skill，安装脚本可以直接复制到目标 skills 目录。
4. 若 `gitnexus`、`node`、`python3` 缺失，安装脚本必须报告失败，不能假装可用。
5. 若 CodeFlow 脚本存在，必须跑一次 headless summary 验证。
6. 若 `merge_graph.py` 不能通过 `py_compile`，安装失败。
7. 安装器无法自动执行脚本时，负责安装的 agent 必须手动执行上述命令并把结果告诉用户。

## 2. 节点对象模型

每个节点必须有稳定编号，编号是主键。

```json
{
  "id": "F-010",
  "title": "Implement graph query API",
  "layer": "F",
  "status": "todo",
  "session": null,
  "kind": "function",
  "file": "scripts/merge_graph.py",
  "functions": ["node_report", "ready_nodes"],
  "tdd": {
    "entry": "tests/test_merge_graph.py",
    "first_fail": "querying unknown node returns error",
    "expected": "json error payload"
  },
  "expected": "Can answer predecessor/successor/progress queries",
  "intent": {
    "one_sentence": "Make graph execution explainable and safe across agent handoffs.",
    "why_now": "The graph is becoming an execution system, not just a diagram.",
    "beneficiary": "agents continuing the work, the user reviewing the work",
    "failure_if_absent": "Agents can call tools correctly but still miss the deeper purpose."
  },
  "value": {
    "principles": ["traceability", "handoff safety", "truth before speed"],
    "non_goals": ["decorative graph output", "unverifiable execution claims"],
    "tradeoffs": ["extra node metadata is worth it when it prevents wrong execution"],
    "success_meaning": "Another agent can explain why this node matters before touching code."
  },
  "why_stack": [
    "Why implement a graph query API?",
    "Why does queryability matter for DAG execution?",
    "Why does DAG execution matter for agent collaboration?",
    "Why does collaboration safety matter to the user?"
  ],
  "value_alignment": {
    "status": "aligned",
    "notes": "The node protects traceable execution and handoff safety."
  },
  "taste_judgement": {
    "main_tension": "Fast execution vs safe handoff.",
    "what_to_optimize": "Blocker correctness and explainability.",
    "what_to_reject": "Tool calls without purpose, diagrams without decision value.",
    "why_this_shape": "A query API turns graph state into executable coordination.",
    "better_than": "Manual reading because it prevents subjective ready-state guesses.",
    "risk_of_overdoing": "Small graphs may not need every report field."
  },
  "interview_evidence": [
    {
      "id": "INT-001",
      "segment": "agent operator",
      "scenario": "choosing the next node after context loss",
      "past_behavior": "Spent time reconstructing why a node was ready from scattered chat and file state.",
      "current_workaround": "Manual inspection of graph, git state, and previous comments.",
      "pain_severity": 5,
      "frequency": "weekly",
      "quote_summary": "The issue is not only what is next, but why it is next.",
      "signals": ["repeated pain", "handoff risk", "clear workaround"]
    }
  ],
  "research_rank": {
    "rank": 1,
    "confidence": "low",
    "sample_size": 1,
    "segments": ["agent operator"],
    "top_evidence": ["INT-001"],
    "why_ranked_here": "Seed rank only; must be validated by 10-20 interviews before becoming stable.",
    "next_research": "Interview maintainers, reviewers, and agent operators about node ranking failures."
  },
  "details": {
    "why": "Execution needs a machine-readable query API.",
    "scope": "Read graph, compute blockers, report ready nodes.",
    "out_of_scope": "Implementing the UI renderer."
  },
  "comments": [
    {
      "at": "2026-05-24T10:30:00+08:00",
      "session": "agent-51fc8cda3c29f04a",
      "author": "codex",
      "type": "execution",
      "body": "Claimed after D-006 was done; first blocker check is clean.",
      "evidence": ["python3 scripts/merge_graph.py --node F-010 .mermaid/current/"]
    }
  ],
  "iterations": [
    {
      "at": "2026-05-24T10:42:00+08:00",
      "session": "agent-51fc8cda3c29f04a",
      "from_status": "doing",
      "to_status": "done",
      "summary": "Implemented query API and validation smoke test.",
      "evidence": ["python3 -m py_compile scripts/merge_graph.py"]
    }
  ],
  "evidence": {
    "gitnexus": ["gitnexus context -r <repo> <symbol>"],
    "codeflow": ["node /Users/copizzah/.codex/skills/codeflow/scripts/query-impact.mjs --repo <repo> --file <file> --format ai"],
    "tests": ["pytest tests/test_merge_graph.py"]
  },
  "mirror": {
    "node": "mermaid-architect.graph-query-api",
    "feature": "mermaid-architect.execution",
    "prev": ["D-006"],
    "next": ["U-002"],
    "deps": ["graph.json", "merge_graph.py"],
    "risk": ["stale graph", "unclaimed concurrent write"]
  },
  "metadata": {
    "priority": "high"
  }
}
```

要求：

- `id` 必填，且唯一
- `title` 必填
- `layer` 必填，只能是 `R / D / F / U`
- `status` 必填，只能是 `todo / doing / blocked / done`
- `session` 可空，用于并发 claim
- `tdd` 建议必填
- `intent` 用于保存这个 node 为什么重要、现在为什么要做、服务谁、不做会失败在哪里
- `value` 用于保存原则、非目标、取舍和成功含义
- `why_stack` 用于保存连续追问链，防止停在第一层 normal 解
- `value_alignment` 用于保存当前 node 是否仍然对齐原始意图和价值
- `taste_judgement` 用于保存主要矛盾、优化目标、拒绝项、拓扑品味和过度设计风险
- `interview_evidence` 用于保存一对一访谈事实、过去行为、workaround、痛点严重度和需求信号
- `research_rank` 用于保存访谈驱动的 rank、样本量、置信度和为什么排在这里
- `details` 用于保存 node 详情、边界、风险和决策理由
- `comments` 用于执行时评论和工作留痕，必须追加，不要覆盖旧记录
- `iterations` 用于状态变化和方案迭代记录，必须追加，不要覆盖旧记录
- `evidence.gitnexus` 记录真实代码关系查询
- `evidence.codeflow` 记录影响面、依赖图、架构健康度查询
- `mirror` 记录 self-mirror 锚点，方便 `rg '@sm:node'` 或图谱对齐
- 其他字段可扩展，但不能破坏上面这些基础字段

编号规则：

- `R-001` 需求层
- `D-001` 数据层
- `F-001` 文件/函数层
- `U-001` UI 层

## 3. 边对象模型

```json
{
  "from": "D-006",
  "to": "F-010",
  "type": "-.->",
  "reason": "data contract maps to implementation surface",
  "evidence": {
    "gitnexus": ["gitnexus query -r <repo> -l 10 \"Graph Query API\""],
    "codeflow": ["query-impact report: F-010 depends on D-006"]
  }
}
```

约束：

- `-->` 同层依赖
- `-.->` 跨层映射
- `==>` 保留给强约束或门禁
- 边可以没有 evidence，但关键路径、跨层边、强约束边必须有 evidence

## 4. 必须具备的查询函数

任何实现这个 skill 的工具层，都必须能回答下面的问题：

1. `get_node(node_id)`
2. `direct_predecessors(node_id)`
3. `all_predecessors(node_id)`
4. `direct_successors(node_id)`
5. `all_successors(node_id)`
6. `blockers(node_id)`
7. `can_execute(node_id)`
8. `ready_nodes()`
9. `next_after(node_id)`
10. `progress()`
11. `node_details(node_id)`
12. `node_comments(node_id)`
13. `node_iterations(node_id)`
14. `evidence_report(node_id)`
15. `mirror_report(node_id)`
16. `intent_report(node_id)`
17. `value_alignment(node_id)`
18. `taste_judgement(node_id)`
19. `rank_report()`
20. `rank_evidence(node_id)`

前 10 个函数是执行模式的最小接口；第 11-15 个函数是协作追溯接口；第 16-18 个函数是意义、价值和品味接口；第 19-20 个函数是访谈驱动的排序接口。

### 4.1 决策含义

- “执行到了 `F-010`”：
  - 用 `get_node(F-010)`
- “它前面依赖有哪些”：
  - 用 `direct_predecessors(F-010)` 和 `all_predecessors(F-010)`
- “是否能执行”：
  - 用 `blockers(F-010)` 和 `can_execute(F-010)`
- “下一个该做什么”：
  - 用 `ready_nodes()`；如果 `F-010` 刚完成，再看 `next_after(F-010)`
- “这个节点为什么这样设计”：
  - 用 `node_details(F-010)` 和 `evidence_report(F-010)`
- “谁在什么时候做过什么”：
  - 用 `node_comments(F-010)` 和 `node_iterations(F-010)`
- “未来 agent 怎么搜索和接力”：
  - 用 `mirror_report(F-010)`
- “为什么这个节点重要”：
  - 用 `intent_report(F-010)`
- “这个节点还对齐原始价值吗”：
  - 用 `value_alignment(F-010)`
- “这个设计有没有品味，为什么不是别的形状”：
  - 用 `taste_judgement(F-010)`
- “哪个需求或 node 应该排前面”：
  - 用 `rank_report()`；没有 10-20 个访谈时必须标低信心
- “这个 rank 的证据是什么”：
  - 用 `rank_evidence(F-010)`，查看 interview_evidence 和 research_rank

## 5. 工具契约

优先使用 bundled script：

```bash
python3 scripts/merge_graph.py --serve .mermaid/current/ --port 5173
python3 scripts/merge_graph.py --api .mermaid/current/ --port 9001
python3 scripts/merge_graph.py --node F-010 .mermaid/current/
python3 scripts/merge_graph.py --ready .mermaid/current/
python3 scripts/merge_graph.py --next F-010 .mermaid/current/
python3 scripts/merge_graph.py --progress .mermaid/current/
python3 scripts/merge_graph.py --details F-010 .mermaid/current/
python3 scripts/merge_graph.py --rank .mermaid/current/
python3 scripts/merge_graph.py --comment F-010 --text "Claimed with clean blockers" .mermaid/current/
python3 scripts/merge_graph.py --iterate F-010 --to doing --summary "Claimed for execution" .mermaid/current/
python3 scripts/merge_graph.py --claim F-010 --session "$AIDS_AGENT_ID" .mermaid/current/
python3 scripts/merge_graph.py --done F-010 --summary "Validated and completed" .mermaid/current/
python3 scripts/merge_graph.py --normalize .mermaid/current/
python3 scripts/merge_graph.py --render .mermaid/current/
python3 scripts/merge_graph.py --validate .mermaid/current/
```

规则：

- `--serve` 必须启动 DAG UI + API，本地可视化默认端口 `5173`
- `--api` 必须启动 API-only 服务，默认端口 `9001`
- `--node` 必须返回节点对象、前序、后续、blockers、能否执行、intent、value、why_stack、value_alignment、taste_judgement、details、comments、iterations、evidence、mirror
- `--ready` 必须返回当前可执行节点集合
- `--next` 必须返回某节点完成后会解锁的节点
- `--progress` 必须返回每层进度和 ready 集合
- `--rank` 必须按 `research_rank.rank` 返回需求/node 排序，并带样本量和置信度
- `--details` 必须返回 node 的完整意图、价值、品味、详情和追溯信息
- `--comment` 必须追加 comment，不得覆盖旧 comment
- `--iterate` 必须追加 iteration，并可同步状态变化
- `--claim` 必须先检查 `can_execute(node)` 和 session 冲突
- `--done` 必须追加 iteration，并清理或保留 session 作为完成证据
- `--normalize` 必须输出对象图 JSON
- `--render` 必须从对象图输出 Mermaid 视图
- `--validate` 必须检查 DAG、孤立节点、跨层断裂、重复编号、缺失意图、缺失价值、缺失品味判断、缺失访谈证据、缺失 research_rank、低样本高置信 rank、缺失详情、缺失 TDD、关键边缺 evidence

HTTP / UI 端点：

- `GET /health`
- `GET /summary`
- `GET /ready`
- `GET /rank`
- `GET /progress`
- `GET /analyze`
- `GET /validate`
- `GET /node/<id>`
- `GET /next/<id>`
- `GET /api/graph?dir=...`
- `GET /api/graph/sse?dir=...`
- `POST /normalize`

## 6. GitNexus + CodeFlow + Self Mirror 证据链

这三者的分工：

- GitNexus：发现真实代码关系，包括 definitions、callers、callees、flows、clusters。
- CodeFlow：发现 repo 级依赖图、影响面、owner/churn、安全提示、跨 repo contract。
- Self Mirror：把 Mermaid node、代码锚点、错误事件、证据命令绑定起来，让未来 agent 可搜索。

Plan/Update 模式中：

1. 若工作涉及现有代码，先用 GitNexus 找真实关系。
2. 若工作会影响多个文件、模块或 repo，使用 CodeFlow 查询影响面。
3. 将 GitNexus/CodeFlow 的关键结果写入 node 或 edge 的 `evidence`。
4. 对架构边界、协议适配、失败路径设计 `mirror` 锚点。
5. 如果工具缺失或查询失败，把失败作为 warning comment 记录到 node，不要静默跳过。

Execution 模式中：

1. claim 前读取 node 的 `evidence` 和 `mirror`。
2. 修改代码时，在架构边界、导出函数、协议适配器、失败路径加入 self-mirror anchors。
3. 重要错误、warning、info 用结构化事件表达，不发匿名字符串。
4. 验证命令必须写入 `comments[].evidence` 或 `iterations[].evidence`。

推荐 GitNexus 命令：

```bash
gitnexus status
gitnexus query -r <repo> -l 10 "<symbols or concepts>"
gitnexus context -r <repo> <symbol>
```

推荐 CodeFlow 命令：

```bash
node /Users/copizzah/.codex/skills/codeflow/scripts/analyze-local.mjs <repo> --format ai --focus-changed
node /Users/copizzah/.codex/skills/codeflow/scripts/query-impact.mjs --repo <repo> --file <file> --format ai
node /Users/copizzah/.codex/skills/codeflow/scripts/query-impact.mjs --repo <repo-a> --repo <repo-b> --changed --format ai
```

推荐 self-mirror 代码锚点：

```ts
// @sm:node <stable-node-id>
// @sm:feature <feature-id>
// @sm:prev <upstream-node-id>
// @sm:next <downstream-node-id>
// @sm:deps <dependency-id>[,<dependency-id>]
// @sm:evidence <test-or-command>
```

## 7. 两种模式

```text
Plan/Update  <->  Execution
```

### 模式 A: Plan/Update

何时进入：

- 新需求
- 用户要求设计 / 拆解 / 架构
- 发现依赖矛盾
- 图不完整
- 需要调研后再定图
- 需要补充 node intent、value、taste_judgement、details、comments、iterations、evidence、mirror
- 需要给需求或 node 做 priority rank

允许：

- 调研相关资料
- 模拟不同场景用户，生成访谈假设
- 设计并执行 The Mom Test 风格一对一访谈
- 读代码和文档
- 使用 GitNexus 和 CodeFlow 生成证据
- 修改对象图
- 生成 Mermaid diff 和完整视图
- 做多方案拓扑对比
- 锁定 TDD 接口
- 写 node 意图、价值、品味判断、详情、风险、工作留痕和迭代记录

不允许：

- 写实现代码
- 跳过图直接开工
- 用没有 evidence 的猜测替代关键路径事实
- 用模拟用户或内部意见替代真实访谈 rank

#### Plan/Update 流程

1. 读取 `graph.json`；若不存在则先 `normalize`
2. 输出当前摘要：节点数、边数、ready 数、关键路径
3. 把需求压缩成一句话、三句话、五句话
4. 写 intent：为什么重要、服务谁、不做会失败在哪里
5. 写 value：保护什么、拒绝什么、成功意味着什么
6. 写 taste_judgement：主要矛盾、为什么是这个拓扑、过度设计风险
7. 做世界调研和场景用户模拟，形成访谈假设
8. 设计一对一访谈问题，避免诱导，聚焦过去行为和真实 workaround
9. 访谈 10-20 个相关用户或场景角色；不足样本时 rank 必须低信心
10. 写 interview_evidence 和 research_rank
11. 自问：我真正需要确认什么、哪些问题只是 normal 解、哪些可以用工具确认
12. 使用 GitNexus 获取真实代码关系
13. 使用 CodeFlow 获取影响面和 repo 级图谱
14. 写需求理解和高杠杆分析
15. 生成四层 DAG diff
16. 给至少 2 套拓扑方案，并比较它们的价值取舍和访谈 rank
17. 锁定新增节点的 TDD、intent、value、taste_judgement、interview_evidence、research_rank、details、evidence、mirror
18. 用户确认后写回对象图
19. 渲染更新后的完整 Mermaid

### 模式 B: Execution

何时进入：

- 对象图已确认
- 当前节点已具备完整依赖信息
- `can_execute(node)` 为 true
- 节点的 intent/value/taste_judgement 足以解释为什么值得执行
- 若多个 ready 节点竞争执行顺序，优先按 research_rank，而不是主观 priority

允许：

- 严格按对象图执行
- 写测试
- 写实现
- 更新节点状态
- 更新 session claim
- 追加 comment 和 iteration
- 补充 evidence 和 self-mirror anchors
- 记录执行中的价值漂移或品味判断变化

不允许：

- 执行图里不存在的工作
- 跳过未完成依赖
- 私自改 DAG 结构
- 覆盖旧 comments 或 iterations
- 无证据地把 blocked 节点改成 done
- 在不理解 intent/value 的情况下机械执行

#### Execution 流程

1. 读取 `ready_nodes()`
2. 选择未被 claim 的 ready 节点
3. 用 `blockers(node_id)` 二次确认
4. 读取 `intent/value/taste_judgement/interview_evidence/research_rank/details/evidence/mirror`
5. 用一句话复述“为什么这个节点值得做，以及访谈证据为什么把它排在这里”
6. claim 节点：`status=doing`，写入 `session`，追加 comment 和 iteration
7. 跑 TDD 的首个失败用例
8. 实现，并在边界位置写 self-mirror anchors
9. 验证，并把命令写入 evidence
10. 标记 `done`，追加 completion iteration 和 value_alignment
11. 查看 `next_after(node_id)` 和新的 `ready_nodes()`

## 8. Sub-agent 并发协议

并发不是“大家一起改”，而是“大家只拿 ready 节点”。

调度规则：

1. 先拿 `ready_nodes()`
2. 去掉已被其他 session claim 的节点
3. 每个 sub-agent 只拿一个节点或一组互不依赖的 ready 节点
4. sub-agent 开工前必须拿到：
   - 节点对象
   - 直接前序
   - 传递前序摘要
   - blockers
   - intent
   - value
   - taste_judgement
   - interview_evidence 摘要
   - research_rank
   - details
   - comments 最近摘要
   - iterations 最近摘要
   - evidence
   - mirror
   - TDD 入口
   - expected
5. sub-agent 结束后只回传：
   - 节点状态变化
   - 新增 comments
   - 新增 iterations
   - 新增 evidence
   - 新增 / 删除边
   - 新增 / 修改节点对象

如果执行中发现矛盾：

1. 停止当前节点
2. 追加 blocked comment
3. 记录矛盾和证据
4. 切回 Plan/Update
5. 改对象图
6. 重新计算 ready 集合

## 9. 输出要求

每次图发生变化后，必须持久化两类产物：

1. 对象图
   - `graph.json`
2. 渲染视图
   - `requirements.mmd`
   - `data.mmd`
   - `files-functions.mmd`
   - `ui.mmd`

对话中的输出不必每次贴全图，但必须至少给：

- L1 一句话：当前主要节点和主要风险
- L2 三句话：节点、价值、证据、下一步
- 当前版本
- 当前节点数 / 边数
- ready 节点
- 当前执行节点
- blockers
- intent / value / taste_judgement 摘要
- interview_evidence / research_rank 摘要
- 下一个推荐节点
- 新增 comments / iterations 摘要
- GitNexus / CodeFlow / test evidence 摘要

## 10. 质量门禁

- [ ] 每个节点都有唯一编号
- [ ] 每个节点都能对象化
- [ ] 每个节点都能查询前序和后续
- [ ] `can_execute(node)` 不是猜的，而是由 blockers 计算出来
- [ ] ready 集合可直接用于 sub-agent 调度
- [ ] 无环
- [ ] 无孤立节点，除非明确声明
- [ ] 跨层链路不断裂：`R -> D -> F -> U`
- [ ] 新增节点都有 TDD
- [ ] 关键节点有 intent
- [ ] 关键节点有 value
- [ ] 关键节点有 taste_judgement
- [ ] 关键节点能说明为什么不是另一种拓扑
- [ ] 关键需求 rank 来自访谈证据
- [ ] 不足 10 个访谈样本的 rank 标注为低信心
- [ ] 访谈记录包含过去行为、当前 workaround、痛点严重度和频率
- [ ] 关键节点有 details
- [ ] 执行节点有 comments 和 iterations
- [ ] 关键路径和跨层边有 GitNexus 或 CodeFlow evidence
- [ ] 代码边界有 self-mirror anchors
- [ ] 失败路径有结构化 error/warning/info 事件

## 11. 快速判断

当用户问这些话时，默认进入对应动作：

- “设计一下新需求”
  - Plan/Update
- “这个节点现在能做吗”
  - `GET /node/<id>`，回退 `--node <id>`
- “现在进度如何”
  - `GET /progress`，回退 `--progress`
- “接下来做什么”
  - `GET /ready`，回退 `--ready`
- “做完 F-010 后谁会被解锁”
  - `GET /next/F-010`，回退 `--next F-010`
- “这个节点的详情是什么”
  - `GET /details/F-010`，回退 `--details F-010`
- “给这个节点留痕 / 评论”
  - `POST /comment/F-010`，回退 `--comment F-010 --text "..."`
- “记录一次迭代”
  - `POST /iterate/F-010`，回退 `--iterate F-010 --summary "..."`
- “找几个 sub agents 并行干”
  - 先取 `ready_nodes()`，再按 claim 状态分配
- “自我 mirror / 可追溯”
  - 输出 node mirror、evidence、comments、iterations，并检查 `@sm` 锚点
- “为什么重要 / 价值是什么”
  - 输出 intent、value、why_stack、value_alignment
- “这个设计有没有品味”
  - 输出 taste_judgement，并检查主要矛盾、拒绝项、取舍和过度设计风险
- “这些需求怎么 rank”
  - 输出 research_rank；如果没有 10-20 个访谈，先进入访谈设计和证据收集
- “rank 的证据是什么”
  - 输出 interview_evidence，检查是否符合 The Mom Test 风格
