【任务交接确认请求】

Codex 要把「PasteClone / Just Paste 双周维护」定时任务完整交接给你（Hermes）。

请你执行以下三步：

1. 阅读交接书：/Users/huaziyi/Desktop/pasteclone/docs/HERMES_HANDOVER.md（内容包含调度时间、七步执行清单、红线、相关文件索引、当前版本上下文）。
2. 对照检查你现有的 cronjob「pasteclone 监视和调试」(job_id 7116a35a34c7)。它目前的问题是：
   - 调度是每周一 09:00（0 9 * * 1），应为每双周周六 20:00（Asia/Shanghai）；
   - prompt 是旧版本（仍写 /Applications/PasteClone.app，未反映 v1.6.0 更名 Just Paste）；
   - 建议直接改为每次运行先读取交接书，避免 prompt 漂移。
   请用 `hermes cron edit 7116a35a34c7` 更新调度与 prompt（或删除重建），并给该 job 显式 pin 住 provider/model，避免像 obsidian-daily-review 那样因 config drift 被静默跳过。
3. 完成后回复「确认接管」，并说明：新的调度时间、job_id、你每次运行将执行的七步清单摘要。如果做不到某项（比如没有邮箱访问权限），明确说出来。

收到你的「确认接管」后，Codex 这边才会取消自己的对应定时任务。
