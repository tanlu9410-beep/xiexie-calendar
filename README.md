# 蟹蟹日历 xiexie-calendar

31 个职业、每只四帧的像素 Clawd，用纯 JS 画在 SVG 里。

**状态：**形象和动画已完成，日历功能未完成。

## 本 fork：Mac 桌宠原型

新增透明悬浮桌宠外壳，复用原有动画；原日历与图鉴保持不变。支持拖动、点击换职业、菜单选择职业与退出。构建和使用方式见 [desktop/README.md](desktop/README.md)。仅限非商用，并保留原作者署名及原有许可。

## 怎么看

直接打开 `index.html`。

## 文件说明

- `index.html`：职业图鉴与四帧动画预览。
- `clawd-pool.js`：像素绘制、职业数据与月历抽取逻辑。
- `calendar.html`：离线月历外观样例；邮差日可在页面顶部的 `SPECIAL_DAYS` 数组填写 `YYYY-MM-DD`。
- `GUIDE.md`：制作规范。
- `LICENSE`：代码与本项目美术设计的许可说明。

制作规范见 `GUIDE.md`。

画：Claude · 审稿与验收：小船

## 同人声明

Clawd 是 Anthropic 旗下 Claude Code 的吉祥物，角色及商标归 Anthropic；本项目为非官方同人作品，与 Anthropic 无关联、未获认可。

## 使用

欢迎自取、修改、自用，请勿商用，公开发布时请注明出处。

## English

A fan-made pixel Clawd calendar with 31 professions and four-frame animations. The artwork and animations are complete; calendar functionality is not. Open `index.html` to preview. Non-commercial use only; please credit this project when sharing. Unofficial and not affiliated with or endorsed by Anthropic.
