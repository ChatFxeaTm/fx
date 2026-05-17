(function () {
  const strategies = window.HYZS_STRATEGIES || [];

  function byId(id) {
    return document.getElementById(id);
  }

  function tagList(items) {
    return `<div class="tag-row">${items.map((item) => `<span class="tag">${item}</span>`).join("")}</div>`;
  }

  function list(items, className = "rule-list") {
    return `<ul class="${className}">${items.map((item) => `<li>${item}</li>`).join("")}</ul>`;
  }

  function renderStrategyCards() {
    const root = byId("strategyCards");
    if (!root) return;
    const base = document.body.dataset.strategyBase || "strategies/";
    root.innerHTML = strategies.map((strategy) => `
      <article class="strategy-card">
        <div>
          <div class="strategy-number">${strategy.number === "总控" ? "总控" : `策略 ${strategy.number}`}</div>
          <h3>${strategy.name}</h3>
          <p class="muted">${strategy.subtitle}</p>
        </div>
        <div class="tag-row">
          <span class="risk ${strategy.riskClass}">${strategy.risk}</span>
          <span class="tag">版本 1.0</span>
        </div>
        <dl>
          <dt>策略定位</dt>
          <dd>${strategy.positioning}</dd>
          <dt>适合行情</dt>
          <dd>${strategy.market}</dd>
          <dt>核心风控</dt>
          <dd>${strategy.riskControls[0]}</dd>
        </dl>
        <div class="links"><a href="${base}${strategy.slug}.html">查看完整策略说明</a></div>
      </article>
    `).join("");
  }

  function renderStrategyPage() {
    const root = byId("strategyDetail");
    if (!root) return;
    const slug = document.body.dataset.strategy;
    const current = strategies.find((item) => item.slug === slug) || strategies[0];
    const index = strategies.findIndex((item) => item.slug === current.slug);
    const previous = strategies[(index - 1 + strategies.length) % strategies.length];
    const next = strategies[(index + 1) % strategies.length];
    const home = document.body.dataset.home || "../index.html";
    const base = document.body.dataset.strategyBase || "./";
    const homeBase = home.endsWith("index.html") ? home.slice(0, -"index.html".length) : home.replace(/[^/]*$/, "");
    const logoSrc = `${homeBase}assets/app_icon.png?v=20260517-symmetry`;

    document.title = `${current.name}｜策略详细介绍`;

    root.innerHTML = `
      <div class="announcement">
        <div class="shell">
          <span><strong>匯鹰中枢策略系统 版本 1.0</strong>｜策略详细介绍</span>
          <span>公开页面只展示产品逻辑与风险边界</span>
        </div>
      </div>

      <div class="topbar">
        <div class="shell">
          <a class="brand" href="${home}"><img class="brand-logo" src="${logoSrc}" alt="匯鹰中枢标志"><span>匯鹰中枢</span></a>
          <nav class="nav">
            <a href="${home}#position">品牌定位</a>
            <a href="${home}#engine">中枢引擎</a>
            <a href="${home}#strategies">策略详细介绍</a>
            <a href="${home}#testing">测试说明</a>
            <a href="${home}#risk">风险边界</a>
          </nav>
        </div>
      </div>

      <header class="hero detail-hero">
        <div class="shell">
          <div class="breadcrumb">首页 / 策略详细介绍 / ${current.name}</div>
          <div class="hero-copy">
            <p class="eyebrow">${current.number === "总控" ? "总控交易程序" : `策略 ${current.number}`}｜版本 1.0</p>
            <h1>${current.name}</h1>
            <p class="lead">${current.subtitle}。${current.overview}</p>
            <div class="hero-actions">
              <a class="button" href="#logic">阅读策略逻辑</a>
              <a class="ghost-button" href="${home}#strategies">返回策略矩阵</a>
            </div>
          </div>
          <div class="detail-summary">
            <div class="summary-item"><strong>策略定位</strong><span>${current.subtitle}</span></div>
            <div class="summary-item"><strong>适合行情</strong><span>${current.market}</span></div>
            <div class="summary-item"><strong>风险等级</strong><span>${current.risk}</span></div>
            <div class="summary-item"><strong>版本体系</strong><span>从 1.0 起步，先验收工程和规则完整性</span></div>
          </div>
        </div>
      </header>

      <main>
        <section class="section" id="logic">
          <div class="shell detail-grid">
            <div>
              <article class="detail-block">
                <p class="eyebrow">策略定位</p>
                <h2>${current.name}解决什么问题</h2>
                <p>${current.positioning}</p>
                <p>${current.boundary}</p>
              </article>

              <article class="detail-block">
                <p class="eyebrow">核心流程</p>
                <h2>从市场结构到候选信号</h2>
                <div class="flow">
                  ${current.flow.map((step) => `<div class="flow-step">${step}</div>`).join("")}
                </div>
              </article>

              <article class="detail-block">
                <p class="eyebrow">信号说明</p>
                <h2>允许与拒绝的判断边界</h2>
                <div class="table-wrap">
                  <table>
                    <tbody>
                      ${current.signals.map((row) => `<tr><th>${row[0]}</th><td>${row[1]}</td></tr>`).join("")}
                    </tbody>
                  </table>
                </div>
              </article>

              <article class="detail-block">
                <p class="eyebrow">风控边界</p>
                <h2>任何候选信号都必须先过风控</h2>
                ${list(current.riskControls)}
              </article>
            </div>

            <aside>
              <article class="detail-block">
                <p class="eyebrow">适合行情</p>
                <h2>更适合在哪些场景观察</h2>
                ${list(current.suitable)}
              </article>

              <article class="detail-block">
                <p class="eyebrow">参数说明</p>
                <h2>版本 1.0 的参数方向</h2>
                ${list(current.params)}
              </article>

              <article class="detail-block">
                <p class="eyebrow">测试说明</p>
                <h2>重点看什么</h2>
                ${list(current.tests)}
              </article>

              <article class="detail-block">
                <p class="eyebrow">禁止事项</p>
                <h2>不可触碰的交易红线</h2>
                ${list(current.forbidden, "rule-list danger")}
              </article>
            </aside>
          </div>
        </section>

        <section class="section compact">
          <div class="shell notice">
            <p class="eyebrow">公开展示边界</p>
            <h2>页面只介绍产品逻辑，不构成交易建议</h2>
            <p>本页面用于说明${current.name}的定位、适合行情、判断流程、风控边界和测试说明。任何真实环境使用都必须经过独立验证，且不得绕过内置风控。</p>
            <div class="footer-actions">
              <a class="button" href="${base}${previous.slug}.html">上一项：${previous.name}</a>
              <a class="button" href="${base}${next.slug}.html">下一项：${next.name}</a>
              <a class="ghost-button" href="${home}#strategies">返回首页</a>
            </div>
          </div>
        </section>
      </main>

      <footer>
        <div class="shell">匯鹰中枢｜${current.name}｜策略详细介绍｜版本 1.0</div>
      </footer>
    `;
  }

  renderStrategyCards();
  renderStrategyPage();
})();
