from pathlib import Path
import re

p = Path('aurora.html')
s = p.read_text(encoding='utf-8')

CN_PRODUCT = '匯鹰·极光 R1'
EN_PRODUCT = 'HUIYING AURORA R1'
CN_BRAND = '匯鹰·量化'
EN_BRAND = 'HUIYING QUANT'

# 1. 顶部品牌：英文模式只显示英文名，中文模式只显示中文名。
old = '<div class="brand"><img src="./aurora-logo.jpg" alt="HUIYING QUANT Logo"><div>HUIYING QUANT<small>匯鹰·量化</small></div></div>'
new = '<div class="brand"><img src="./aurora-logo.jpg" alt="HUIYING QUANT Logo"><div><span class="en">HUIYING QUANT</span><span class="zh">匯鹰·量化</span><small><span class="en">HUIYING AURORA R1</span><span class="zh">匯鹰·极光 R1</span></small></div></div>'
if old not in s:
    raise SystemExit('header name block not found')
s = s.replace(old, new, 1)

# 2. 首屏标题：英文和中文各用各自正式名称。
old = '<div class="eyebrow">OFFICIAL STRATEGY DOCUMENTATION · R1</div><h1>HUIYING<br>AURORA R1</h1>'
new = '<div class="eyebrow"><span class="en">OFFICIAL STRATEGY DOCUMENTATION · R1</span><span class="zh">R1 官方策略文档</span></div><h1 class="en">HUIYING<br>AURORA R1</h1><h1 class="zh">匯鹰·<br>极光 R1</h1>'
if old not in s:
    raise SystemExit('hero name block not found')
s = s.replace(old, new, 1)

# 3. 中文H1在中文模式下保持块级显示，不改变其他布局。
css_old = '.zh{display:none}html[data-lang="zh"] .en{display:none}html[data-lang="zh"] .zh{display:initial}html[data-lang="zh"] div.zh{display:block}'
css_new = css_old + 'html[data-lang="zh"] h1.zh{display:block}'
if css_old not in s:
    raise SystemExit('language css block not found')
s = s.replace(css_old, css_new, 1)

# 4. 正文中的产品名按语言分别统一。
def replace_in_lang_tags(text, lang, replacement):
    pattern = re.compile(r'(<(?:p|span|h[1-6]|strong|li)[^>]*class="[^"]*\\b' + lang + r'\\b[^"]*"[^>]*>[^<]*)AURORA R1')
    return pattern.sub(lambda m: m.group(1) + replacement, text)

s = replace_in_lang_tags(s, 'en', EN_PRODUCT)
s = replace_in_lang_tags(s, 'zh', CN_PRODUCT)

# 当前页面中几个明确的产品名位置。
s = s.replace('aria-label="AURORA R1 strategy engine visualization"', 'aria-label="HUIYING AURORA R1 strategy engine visualization"')
s = s.replace('Attach AURORA R1 to an XAUUSD 5-minute chart.', 'Attach HUIYING AURORA R1 to an XAUUSD 5-minute chart.')
s = s.replace('AURORA R1应加载在XAUUSD黄金5分钟图。', '匯鹰·极光 R1应加载在XAUUSD黄金5分钟图。')
s = s.replace('>AURORA R1 combines', '>HUIYING AURORA R1 combines')
s = s.replace('>AURORA R1 is not', '>HUIYING AURORA R1 is not')
s = s.replace('>AURORA R1 is automated', '>HUIYING AURORA R1 is automated')
s = s.replace('>AURORA R1将', '>匯鹰·极光 R1将')
s = s.replace('>AURORA R1不是', '>匯鹰·极光 R1不是')
s = s.replace('>AURORA R1仅', '>匯鹰·极光 R1仅')

# 5. 页脚品牌和版权按语言分别显示。
old = '<strong style="color:var(--gold2)">HUIYING QUANT · 匯鹰·量化</strong>'
new = '<strong style="color:var(--gold2)"><span class="en">HUIYING QUANT</span><span class="zh">匯鹰·量化</span></strong>'
if old not in s:
    raise SystemExit('footer brand block not found')
s = s.replace(old, new, 1)

s = s.replace('© 2026 HUIYING QUANT. All rights reserved.', '<span class="en">© 2026 HUIYING QUANT. All rights reserved.</span><span class="zh">© 2026 匯鹰·量化。保留所有权利。</span>', 1)

# 6. 切换语言时同步浏览器标题。
old = "btn.textContent=lang==='zh'?'EN':'中文';localStorage.setItem('aurora-lang',lang);"
new = "btn.textContent=lang==='zh'?'EN':'中文';document.title=lang==='zh'?'匯鹰·极光 R1｜官方策略说明':'HUIYING AURORA R1 | Official Strategy Guide';localStorage.setItem('aurora-lang',lang);"
if old not in s:
    raise SystemExit('language script block not found')
s = s.replace(old, new, 1)

# 7. 防止错误音译或简体替换混入。
for bad in ('慧英', '奥罗拉', '奧羅拉', '汇鹰·极光', '汇鹰·量化'):
    if bad in s:
        raise SystemExit(f'forbidden name remains: {bad}')

for required in (CN_PRODUCT, EN_PRODUCT, CN_BRAND, EN_BRAND):
    if required not in s:
        raise SystemExit(f'missing official name: {required}')

p.write_text(s, encoding='utf-8')
print('Aurora names unified successfully')
