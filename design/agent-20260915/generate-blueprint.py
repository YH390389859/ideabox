"""Editable native-vector design board for the Daily Loom conversational agent."""
from pathlib import Path
from html import escape
from math import sin, cos, pi

ROOT = Path(__file__).resolve().parent
BG, INK, BLUE, LIME, CLAY = '#F3F0E8', '#202A2B', '#3555E8', '#D9EB77', '#C96C50'
DIM, LINE = '#737A73', '#D3D6C9'
out = []
def emit(s): out.append(s)
def text(x,y,s,size=14,fill=INK,weight=400,extra=''):
    emit(f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" font-weight="{weight}" {extra}>{escape(s)}</text>')
def mono(x,y,s,size=10,fill=DIM,extra=''):
    text(x,y,s,size,fill,500,f'font-family="SFMono-Regular, Menlo, monospace" {extra}')
def rect(x,y,w,h,fill,extra=''):
    emit(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" {extra}/>')
def path(d,stroke=INK,width=1,fill='none',extra=''):
    emit(f'<path d="{d}" stroke="{stroke}" stroke-width="{width}" fill="{fill}" {extra}/>')
def line(x1,y1,x2,y2,color=LINE,width=1,extra=''):
    path(f'M{x1} {y1}L{x2} {y2}',color,width,extra=extra)
def circle(x,y,r,fill,extra=''):
    emit(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" {extra}/>')
def group(transform=''):
    emit(f'<g transform="{transform}">' if transform else '<g>')
def end(): emit('</g>')
def shuttle(x,y,w=50,h=32,fill=INK):
    path(f'M{x} {y+h/2}Q{x+w/2} {y-h*.22} {x+w} {y+h/2}Q{x+w/2} {y+h*1.22} {x} {y+h/2}Z','none',0,fill)
def arrow(x,y,color=INK):
    path(f'M{x-5} {y+5}L{x+5} {y-5}M{x-4} {y-5}H{x+5}V{y+4}',color,1.4,extra='stroke-linecap="round" stroke-linejoin="round"')
def closephone():
    rect(133,857,136,5,INK,'rx="2.5"')
    end(); end()
def startphone(x):
    group(f'translate({x} 172)')
    rect(-1,-1,404,876,BG,'rx="44" stroke="#ADB4A8" stroke-width=".7" filter="url(#deviceShadow)"')
    emit('<g clip-path="url(#phoneClip)">')
    rect(0,0,402,874,BG)
    text(31,33,'9:41',14,INK,650)
    rect(142,10,118,28,INK,'rx="14"')
    for n,h in enumerate([4,7,10,13]): rect(309+n*5,31-h,3,h,INK,'rx="1"')
    path('M337 23Q345 16 353 23M340 26Q345 21 350 26M344 29L346 29',INK,1.8,extra='stroke-linecap="round"')
    rect(361,20,23,12,'none','rx="3" stroke="#202A2B" stroke-width="1"')
    rect(363,22,18,8,INK,'rx="1.5"'); rect(385,24,2,4,INK,'rx="1"')
    path('M35 68L27 76L35 84',INK,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
def settings(x=365,y=76):
    circle(x,y,9,'none','stroke="#202A2B" stroke-width="1.1"')
    circle(x,y,3,'none','stroke="#202A2B" stroke-width="1.1"')
    for i in range(8):
        t=i*pi/4
        line(x+10*cos(t),y+10*sin(t),x+12*cos(t),y+12*sin(t),INK,1.2)
def inputbar(label):
    line(24,760,378,760,INK,.8)
    text(24,794,label,14,DIM)
    shuttle(320,773,58,37)
    path('M342 797L349 786L356 797M349 787V801',BG,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
    mono(24,824,'DEEPSEEK',8.5,DIM,extra='letter-spacing="1.2"')
    circle(94,821,2.5,BLUE)
    text(106,824,'把一句话，变成一段日常。',9,DIM)

emit('''<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="1170" viewBox="0 0 1500 1170" role="img" aria-labelledby="title description">
<title id="title">日常织机 · 对话式 Agent 三屏设计稿</title>
<desc id="description">对话采集、可撤回的操作回执、DeepSeek 自带密钥设置。暖白纸面、流动线束、折页和穿线回执构成原生 iPhone 界面。</desc>
<defs>
<clipPath id="phoneClip"><rect width="402" height="874" rx="43"/></clipPath>
<filter id="deviceShadow" x="-20%" y="-10%" width="140%" height="130%"><feDropShadow dx="0" dy="12" stdDeviation="18" flood-color="#202A2B" flood-opacity=".065"/></filter>
<filter id="paperShadow" x="-15%" y="-20%" width="140%" height="160%"><feDropShadow dx="0" dy="5" stdDeviation="4" flood-color="#202A2B" flood-opacity=".04"/></filter>
<linearGradient id="acid" x1="0" x2="1"><stop stop-color="#E0EB94"/><stop offset="1" stop-color="#D9EB77"/></linearGradient>
</defs>
<g font-family="-apple-system, BlinkMacSystemFont, PingFang SC, Hiragino Sans GB, sans-serif">
''')
rect(0,0,1500,1170,'#E7E7DE')
mono(84,47,'DAILY LOOM   /   CONVERSATION AS MATERIAL',11,INK,extra='letter-spacing="1.6"')
text(82,105,'说一点，织进去。',40,INK,650,extra='letter-spacing="-1.8"')
text(440,103,'让一句话，落进真实的生活。',15,DIM)
mono(1418,48,'15 SEP 2026',11,INK,extra='text-anchor="end"')
mono(1418,77,'AGENT STUDY / 402 × 874 PT',10,DIM,extra='text-anchor="end"')
line(84,132,1418,132,'#C5CBBF',.8)

# 01 — empty state. Fine individual lines compose a loose three-dimensional loop.
startphone(84)
mono(201,80,'一段新对话',11,INK,extra='text-anchor="middle"')
settings()
mono(25,131,'04 / TALK TO LOOM',9,BLUE,extra='letter-spacing="1.8"')
text(22,186,'说一点，',43,INK,650,extra='letter-spacing="-2"')
text(22,238,'织进去。',43,INK,650,extra='letter-spacing="-2"')
text(25,272,'日常、习惯、灵感，都从一句话开始。',12,DIM)
group('translate(15 288)')
def curve(t,s):
    # A torsioned loop with one opening and an off-axis second strand.
    x=187+124*cos(t)+s*22*cos(2*t+.65)
    y=130+84*sin(2*t)*.8+35*sin(t)+s*(13*cos(t)-5*sin(3*t))
    return x,y
def sample(points): return 'M'+'L'.join(f'{x:.2f} {y:.2f}' for x,y in points)
for i in range(41):
    s=(i-20)/20
    points=[curve(.1+j*2*pi/260,s) for j in range(250)]
    path(sample(points),BLUE,.58 if i%5 else .82,extra=f'opacity="{.55 if i%5 else .85}"')
# A loose thread leaves the loop and returns toward the prompt suggestions.
path('M32 178C-11 226 82 247 127 228C207 195 264 207 278 249C287 276 314 286 340 277',BLUE,.85)
for i in range(7):
    path(f'M{48+i*.6} {78+i*.7}C{100+i*.7} {35+i*.5} {113+i*.8} {172+i*.8} {204+i*.5} {172+i*.4}C{254+i*.4} {172+i*.3} {262+i*.8} {119+i*.5} {315+i*.4} {96+i*.6}',CLAY,.62,extra='opacity=".78"')
group('translate(253 164) rotate(-30)')
shuttle(0,0,76,31,LIME)
path('M17 15.5H58',INK,.8)
circle(58,15.5,2.5,BG)
end()
mono(19,290,'A THOUGHT BECOMES A THREAD',7.2,DIM,extra='letter-spacing=".7"')
end()
line(24,622,378,622,LINE,.7)
text(24,650,'从这里开始',10,DIM)
for y,label,number in [(684,'记下今天的小事','01'),(727,'帮我整理一个想法','02')]:
    mono(24,y,number,9,BLUE)
    text(52,y,label,14,INK,500)
    arrow(365,y-5,INK)
    if y==684: line(52,701,378,701,LINE,.6)
inputbar('今天有什么想留下？')
closephone()

# 02 — actual conversational result. A material receipt replaces a generic bubble.
startphone(550)
mono(201,80,'今天 · 09:41',10,INK,extra='text-anchor="middle"')
settings()
mono(25,131,'04 / A THREAD, KEPT',9,BLUE,extra='letter-spacing="1.6"')
text(22,181,'这一段，已织好。',31,INK,650,extra='letter-spacing="-1.1"')
text(25,212,'两件小事，已经各自落好了位置。',12,DIM)
group('translate(24 243)')
path('M0 0H354V101L345 97L337 102L329 97L321 102L313 97L305 102L297 97L289 102L281 97L273 102L265 97L257 102L249 97L241 102L233 97L225 102L217 97L209 102L201 97L193 102L185 97L177 102L169 97L161 102L153 97L145 102L137 97L129 102L121 97L113 102L105 97L97 102L89 97L81 102L73 97L65 102L57 97L49 102L41 97L33 102L25 97L17 102L9 97L0 101Z','none',0,'#E7E7DC')
mono(16,22,'YOU / 09:41',8,DIM,extra='letter-spacing="1"')
text(16,48,'阅读打卡完成。也记住这句话：',13,INK,500)
text(16,72,'留白，是为了让重要的事发生。',13,INK,500)
end()
line(34,382,34,631,BLUE,1)
circle(34,386,4.5,BG,'stroke="#3555E8" stroke-width="1.2"')
path('M34 386H52',BLUE,1)
group('translate(52 365)')
rect(0,0,326,100,'url(#acid)')
for y in [15,35,55,75,95]: circle(0,y,2.5,BG)
mono(16,23,'01 / HABIT',8.5,INK,extra='letter-spacing="1"')
text(16,54,'阅读',21,INK,650)
circle(303,22,8,INK)
path('M299 22L302 25L307 19',LIME,1.25,extra='stroke-linecap="round" stroke-linejoin="round"')
text(16,80,'今日已完成',11,INK,500)
text(256,80,'查看',10,INK,550)
text(295,80,'撤回',10,INK,550)
end()
circle(34,508,4.5,BG,'stroke="#3555E8" stroke-width="1.2"')
path('M34 508H52',BLUE,1)
group('translate(52 487)')
path('M0 0H302L326 24V148H0Z','#D1D4C7',.7,'#FBFAF3','filter="url(#paperShadow)"')
path('M302 0V24H326','none',0,'#E0DFD2')
line(302,24,326,24,'#CDD1C2',.6)
mono(16,23,'02 / DIARY',8.5,DIM,extra='letter-spacing="1"')
text(16,57,'留白，是为了让',19,INK,600)
text(16,84,'重要的事发生。',19,INK,600)
line(16,104,310,104,LINE,.7)
text(16,128,'已保留你的原话',10,DIM)
text(256,128,'查看',10,INK,550)
text(295,128,'撤回',10,INK,550)
end()
circle(34,636,2.2,BLUE)
mono(24,673,'LOOM',8,BLUE,extra='letter-spacing="1.3"')
text(24,698,'阅读已打卡，这句话也替你留下了。',12,INK)
text(24,724,'还想接着记一点吗？',12,DIM)
inputbar('继续留下一根线…')
closephone()

# 03 — own-key settings. Direct, understandable and visibly editable.
startphone(1016)
mono(201,80,'连接设置',11,INK,extra='text-anchor="middle"')
mono(25,131,'05 / THE QUIET ENGINE',9,BLUE,extra='letter-spacing="1.6"')
text(22,181,'接上你的灵感。',33,INK,650,extra='letter-spacing="-1.1"')
text(25,212,'用你自己的 DeepSeek，陪你记下生活。',12,DIM)
group('translate(24 243)')
rect(0,0,354,107,'#E7E9DA')
for i in range(16):
    path(f'M{18+i*2} 73C{52+i*2} 10 {93+i*2} 106 {129+i*2} 46',BLUE,.6,extra='opacity=".72"')
shuttle(54,37,56,27,LIME)
line(68,50.5,96,50.5,INK,.6)
mono(181,29,'POWERED BY',8,DIM,extra='letter-spacing="1.3"')
text(181,56,'DeepSeek',23,INK,650)
circle(185,80,2.5,CLAY)
text(195,84,'等待连接',10,DIM)
end()
text(24,388,'API KEY',10,INK,600,extra='letter-spacing="1.2"')
text(378,388,'仅储存在本机',10,DIM,extra='text-anchor="end"')
rect(24,405,354,54,'#FBFAF3','rx="3" stroke="#C6CDBC" stroke-width=".8"')
mono(40,437,'sk-••••••••••••••••••••',13,INK,extra='letter-spacing=".7"')
path('M342 432Q352 419 362 432Q352 445 342 432Z',DIM,1)
circle(352,432,3,'none','stroke="#737A73" stroke-width="1"')
text(24,496,'模型',11,INK,600)
text(378,496,'可编辑',10,DIM,extra='text-anchor="end"')
rect(24,511,354,54,'#FBFAF3','rx="3" stroke="#C6CDBC" stroke-width=".8"')
mono(40,543,'deepseek-flash',14,INK)
path('M345 539L355 529L359 533L349 543L344 544Z',DIM,1)
text(24,589,'填写你账号可用的模型名称。',10,DIM)
rect(24,616,354,52,INK,'rx="3"')
text(201,648,'保存并连接',14,BG,600,extra='text-anchor="middle"')
arrow(352,641,BG)
text(201,704,'测试连接',12,BLUE,550,extra='text-anchor="middle"')
line(24,732,378,732,LINE,.7)
circle(32,755,5,'none','stroke="#737A73" stroke-width=".9"')
line(32,753,32,758,DIM,.9)
circle(32,750.5,.7,DIM)
text(47,759,'密钥通过 iOS Keychain 安全储存。',10,DIM)
text(47,782,'对话消息与必要的记录上下文会发送至',10,DIM)
text(47,800,'DeepSeek；日常数据继续保存在本机。',10,DIM)
closephone()

for x,n,label,caption in [(84,'01','CAPTURE','一句话成为线，穿过日常、习惯与灵感。'),(550,'02','ACTION RECEIPTS','动作留下回执，每一笔都能查看与撤回。'),(1016,'03','YOUR CONNECTION','自带密钥，原生调用，数据落回你的手机。')]:
    mono(x,1076,f'{n}  {label}',10,INK,extra='letter-spacing="1.4"')
    text(x,1101,caption,12,DIM)
line(84,1127,1418,1127,'#C5CBBF',.8)
mono(84,1150,'PAPER / THREAD / REAL ACTIONS / QUIET MOTION',8.5,INK,extra='letter-spacing="1.2"')
for i,(color,label) in enumerate([(BG,'PAPER'),(INK,'INK'),(BLUE,'COBALT'),(LIME,'ACID'),(CLAY,'CLAY')]):
    x=1036+i*77
    rect(x,1141,11,11,color,'stroke="#AEB7A6" stroke-width=".4"')
    mono(x+16,1150,label,7,DIM)
end();emit('</svg>')
(ROOT/'blueprint.svg').write_text('\n'.join(out),encoding='utf-8')
print(ROOT/'blueprint.svg')
