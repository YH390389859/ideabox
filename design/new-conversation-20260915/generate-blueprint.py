"""Editable native-vector study: a visible new thread and paper confirmation."""
from pathlib import Path
from html import escape
from math import sin, cos, pi
ROOT=Path(__file__).resolve().parent
BG,INK,BLUE,GREEN,DIM,LINE='#F3F0E8','#202A2B','#3555E8','#E2E8D4','#737A73','#D3D6C9'
out=[]
def emit(s):out.append(s)
def text(x,y,s,size=14,fill=INK,weight=400,extra=''):
    emit(f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" font-weight="{weight}" {extra}>{escape(s)}</text>')
def mono(x,y,s,size=10,fill=DIM,extra=''):text(x,y,s,size,fill,500,f'font-family="SFMono-Regular, Menlo, monospace" {extra}')
def rect(x,y,w,h,fill,extra=''):emit(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" {extra}/>')
def path(d,stroke=INK,width=1,fill='none',extra=''):emit(f'<path d="{d}" stroke="{stroke}" stroke-width="{width}" fill="{fill}" {extra}/>')
def line(x1,y1,x2,y2,color=LINE,width=1,extra=''):path(f'M{x1} {y1}L{x2} {y2}',color,width,extra=extra)
def circle(x,y,r,fill,extra=''):emit(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" {extra}/>')
def group(transform=''):emit(f'<g transform="{transform}">' if transform else '<g>')
def end():emit('</g>')
def shuttle(x,y,w=50,h=32,fill=INK):path(f'M{x} {y+h/2}Q{x+w/2} {y-h*.22} {x+w} {y+h/2}Q{x+w/2} {y+h*1.22} {x} {y+h/2}Z','none',0,fill)
def settings(x=344,y=76):
    circle(x,y,8,'none','stroke="#202A2B" stroke-width="1.1"');circle(x,y,2.7,'none','stroke="#202A2B" stroke-width="1.1"')
    for i in range(8):
        t=i*pi/4;line(x+9*cos(t),y+9*sin(t),x+12*cos(t),y+12*sin(t),INK,1.1)
def thread_icon(x,y,color=INK):
    path(f'M{x-7} {y+4}C{x-1} {y+4} {x-3} {y-5} {x+2} {y-5}C{x+7} {y-5} {x+6} {y+2} {x+1} {y+2}C{x-4} {y+2} {x-2} {y-3} {x+3} {y-3}H{x+8}',color,1.3,extra='stroke-linecap="round"')
def mic(x,y,color=INK):
    rect(x-3.5,y-10,7,14,'none',f'rx="3.5" stroke="{color}" stroke-width="1.4"')
    path(f'M{x-7} {y-2}V{y+1}Q{x-7} {y+8} {x} {y+8}Q{x+7} {y+8} {x+7} {y+1}V{y-2}M{x} {y+8}V{y+12}M{x-4} {y+12}H{x+4}',color,1.4,extra='stroke-linecap="round"')
def phone(x):
    group(f'translate({x} 166)')
    rect(-1,-1,377,814,BG,'rx="43" stroke="#ADB4A8" stroke-width=".65" filter="url(#deviceShadow)"')
    emit('<g clip-path="url(#phoneClip)">');rect(0,0,375,812,BG)
    text(29,32,'9:41',14,INK,650);rect(130,10,115,28,INK,'rx="14"')
    for n,h in enumerate([4,7,10,13]):rect(287+n*5,31-h,3,h,INK,'rx="1"')
    path('M315 23Q323 16 331 23M318 26Q323 21 328 26M322 29L324 29',INK,1.8,extra='stroke-linecap="round"')
    rect(338,20,22,12,'none','rx="3" stroke="#202A2B" stroke-width="1"');rect(340,22,17,8,INK,'rx="1.5"');rect(361,24,2,4,INK,'rx="1"')
    path('M33 68L25 76L33 84',INK,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
    text(110,80,'今天 · 09:41',11,INK,500,extra='text-anchor="middle"')
    rect(221,59,94,34,GREEN,'rx="17"');thread_icon(239,76);text(277,80,'新对话',12,INK,550,extra='text-anchor="middle"')
    settings();line(23,103,352,103,LINE,.65)
    mono(23,141,'LOOM',8,BLUE,extra='letter-spacing="1.3"');text(23,169,'生活里的小事，我们慢慢记。',13,INK)
    rect(23,203,329,71,'#E7E7DC','rx="2"');mono(39,225,'YOU / 09:32',8,DIM,extra='letter-spacing=".8"');text(39,251,'今天读完了二十页书，帮我打个卡。',12,INK,450)
    line(32,297,32,410,BLUE,1);circle(32,305,4,BG,'stroke="#3555E8" stroke-width="1.2"');line(36,305,49,305,BLUE,1)
    rect(49,290,303,108,'#DDE99A');
    for y in [305,325,345,365,385]:circle(49,y,2.5,BG)
    mono(66,313,'01 / HABIT',8,INK,extra='letter-spacing=".9"');text(66,346,'阅读',23,INK,600)
    text(66,378,'今日已完成',11,INK);text(329,378,'查看   撤回',10,INK,extra='text-anchor="end"')
    circle(329,310,7,INK);path('M325 310L328 313L333 307','#DDE99A',1.1,extra='stroke-linecap="round"')
    mono(23,437,'LOOM',8,BLUE,extra='letter-spacing="1.3"');text(23,465,'替你记好了。今天又织进一小段。',12,INK)
    rect(23,500,329,88,'#E7E7DC','rx="2"');mono(39,523,'YOU / 09:41',8,DIM,extra='letter-spacing=".8"');text(39,548,'还有一个想法，先帮我留个位置。',12,INK,450);text(39,571,'晚一点再慢慢整理。',12,INK,450)
    mono(23,620,'LOOM',8,BLUE,extra='letter-spacing="1.3"');text(23,647,'我在这里。随时接着说。',14,INK,500)
    line(23,698,352,698,INK,.8);mic(44,732);text(77,737,'继续留下一根线…',14,DIM)
    shuttle(295,711,57,41,INK);path('M318 736L324 726L330 736M324 727V741',BG,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
    mono(23,777,'DEEPSEEK',8,DIM,extra='letter-spacing=".8"');circle(89,774,2.5,BLUE)
    text(322,777,'自己记',13,INK,500,extra='text-anchor="end"');path('M336 777L344 769M337 769H344V776',INK,1.3,extra='stroke-linecap="round"')
def closephone():rect(120,796,135,5,INK,'rx="2.5"');end();end()
def confirmation():
    rect(0,0,375,812,INK,'opacity=".48"')
    # Suspended paper, corner stitch and a single continuing cobalt thread.
    rect(22,249,331,348,'#F7F4EB','rx="23" filter="url(#paperShadow)"')
    rect(36,260,303,321,'none','rx="15" stroke="#DADCCF" stroke-width=".65" stroke-dasharray="1 4"')
    path('M59 293C88 293 105 273 111 286C118 302 80 315 78 299C75 282 116 280 127 294C138 308 113 319 103 309C92 298 121 286 135 295', '#B5BFA7',1.6,extra='stroke-linecap="round"')
    path('M117 306C129 303 129 289 140 289C157 289 153 309 142 305C130 300 150 291 162 296C179 303 177 280 196 280H231', BLUE,1.5,extra='stroke-linecap="round"')
    circle(232,280,2.5,BLUE)
    # 44-point dismiss target, without heavyweight platform button chrome.
    path('M315 273L325 283M325 273L315 283',DIM,1.4,extra='stroke-linecap="round"')
    mono(48,343,'BEGIN AGAIN',8,BLUE,extra='letter-spacing="1.6"')
    text(48,380,'再起一线',30,INK,650,extra='letter-spacing="-.8"')
    text(48,414,'将清空本机的当前对话。',13,DIM)
    text(48,437,'已保存的日常、习惯和收集仍会保留。',13,DIM)
    rect(46,465,283,49,INK,'rx="24.5"')
    text(187.5,495,'清空并开始',14,BG,550,extra='text-anchor="middle"')
    path('M294 493L302 485M295 485H302V492',BG,1.3,extra='stroke-linecap="round"')
    text(187.5,550,'继续这段对话',13,INK,500,extra='text-anchor="middle"')
    line(137,559,238,559,'#B6BEAC',.7)

emit('''<svg xmlns="http://www.w3.org/2000/svg" width="1120" height="1140" viewBox="0 0 1120 1140" role="img" aria-labelledby="title description">
<title id="title">日常织机 · 再起一线</title><desc id="description">明确可见的新对话按钮，沿用暖绿胶囊和织线图标。展开后是一张安静的暖白确认纸片，明确说明清空当前对话且保留已保存内容。</desc>
<defs><clipPath id="phoneClip"><rect width="375" height="812" rx="42"/></clipPath><filter id="deviceShadow" x="-20%" y="-10%" width="140%" height="130%"><feDropShadow dx="0" dy="12" stdDeviation="18" flood-color="#202A2B" flood-opacity=".065"/></filter><filter id="paperShadow" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="18" stdDeviation="22" flood-color="#121A18" flood-opacity=".20"/></filter></defs><g font-family="-apple-system, BlinkMacSystemFont, PingFang SC, Hiragino Sans GB, sans-serif">''')
rect(0,0,1120,1140,'#E7E7DE')
mono(105,45,'DAILY LOOM   /   BEGIN AGAIN',10,INK,extra='letter-spacing="1.5"')
text(103,105,'一段话落下，再起一线。',35,INK,650,extra='letter-spacing="-1.2"')
mono(1014,46,'15 SEP 2026',10,INK,extra='text-anchor="end"');text(1014,102,'新对话 / 375 pt 设计',12,DIM,extra='text-anchor="end"')
line(106,132,1013,132,'#C5CBBF',.8)
phone(106);closephone()
phone(638);confirmation();closephone()
mono(106,1014,'01 / AN INVITATION, ALWAYS IN SIGHT',9,INK,extra='letter-spacing="1.1"')
text(106,1040,'轻盈的「新对话」，留在触手可及之处。',12,DIM)
mono(638,1014,'02 / A QUIET MOMENT BEFORE BEGINNING',9,INK,extra='letter-spacing="1.1"')
text(638,1040,'旧线收束，新线延展。先说清楚，再开始。',12,DIM)
line(106,1070,1013,1070,'#C5CBBF',.8)
mono(106,1096,'VISIBLE ENTRY / PAPER CONFIRMATION / SAVED RECORDS STAY',8,INK,extra='letter-spacing="1"')
text(1013,1096,'44 pt 可点区域 · 支持减弱动态效果',10,DIM,extra='text-anchor="end"')
end();emit('</svg>')
(ROOT/'blueprint.svg').write_text('\n'.join(out),encoding='utf-8')
print(ROOT/'blueprint.svg')
