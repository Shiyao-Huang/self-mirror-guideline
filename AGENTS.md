# Agent Instructions

本仓库只维护 Self Mirror 规范，不放 Adocker SDK 实现代码。

执行任务时遵守：

1. 修改规范前先确认改动属于 comment marker、event contract、Mermaid adjacency、workflow、example 中哪一类。
2. 新增规则必须能回答 Agent 的接管问题：我在哪、前置是谁、后置是谁、依赖是谁、失败时怎么办。
3. 不写装饰性注释；只写能被 `rg '@sm:'`、GitNexus、gbrain 检索和验证的结构注释。
4. 示例代码必须包含至少一个成功路径、一个 warning/info 路径、一个 error 路径。
5. README 保持决策入口，详细规则放入 `references/`。

