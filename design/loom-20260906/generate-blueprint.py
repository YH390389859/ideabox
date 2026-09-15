"""Deterministic, editable vector design board. Writes only to this directory."""
from pathlib import Path
from html import escape
from math import sin, cos, pi

ROOT = Path(__file__).resolve().parent
BG, INK, BLUE, LIME, RUST = '#F3F0E8', '#202A2B', '#3555E8', '#D9EB77', '#C96C50'
DIM, LINE = '#7C827C', '#D8D8CB'
out = []

def e(s): out.append(s)
def text(x,y,s,size=14,fill=INK,weight=400,extra=''):
    e(f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" font-weight="{weight}" {extra}>{escape(s)}</text>')
def rect(x,y,w,h,fill,extra=''):
    e(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" {extra}/>')
def path(d,stroke=INK,width=1,fill='none',extra=''):
    e(f'<path d="{d}" stroke="{stroke}" stroke-width="{width}" fill="{fill}" {extra}/>')
def line(x1,y1,x2,y2,color=LINE,width=1,extra=''):
    path(f'M{x1} {y1}L{x2} {y2}',color,width,extra=extra)
def circle(x,y,r,fill,extra=''):
    e(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" {extra}/>')
def mono(x,y,s,size=10,fill=DIM,extra=''):
    text(x,y,s,size,fill,500,f'font-family="SFMono-Regular, Menlo, monospace" {extra}')
def group(transform=''):
    e(f'<g transform="{transform}">' if transform else '<g>')
def end(): e('</g>')

e('''<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="1150" viewBox="0 0 1500 1150" role="img" aria-labelledby="title description">
<title id="title">IdeaBox 日常织机 · 三屏精确布局设计</title>
<desc id="description">暖纸白界面上，以真实习惯数据构成悬浮织片，以可操作线织矩阵管理习惯，以打孔纸、磁带和折角纸收集灵感。三个页面分别为今天、习惯、收集。</desc>
<defs>
  <clipPath id="phoneClip"><rect width="402" height="874" rx="43"/></clipPath>
  <clipPath id="matrixClip"><rect x="120" y="227" width="258" height="412"/></clipPath>
  <filter id="deviceShadow" x="-20%" y="-10%" width="140%" height="130%"><feDropShadow dx="0" dy="13" stdDeviation="18" flood-color="#202A2B" flood-opacity=".075"/></filter>
  <filter id="fabricShadow" x="-50%" y="-100%" width="200%" height="300%"><feGaussianBlur stdDeviation="12"/></filter>
  <linearGradient id="paperShade" x1="0" x2="1"><stop stop-color="#DFEB9D"/><stop offset=".5" stop-color="#D9EB77"/><stop offset="1" stop-color="#D3E675"/></linearGradient>
  <linearGradient id="tapeShade" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#4362EB"/><stop offset="1" stop-color="#2948D5"/></linearGradient>
  <linearGradient id="matrixFade" x1="0" x2="1"><stop stop-color="#F3F0E8"/><stop offset="1" stop-color="#F3F0E8" stop-opacity="0"/></linearGradient>
</defs>
<g font-family="-apple-system, BlinkMacSystemFont, PingFang SC, Hiragino Sans GB, sans-serif">
''')
rect(0,0,1500,1150,'#E7E7DE')
mono(84,49,'IDEABOX   /   CREATIVE DIRECTION 02',12,INK,extra='letter-spacing="1.8"')
text(82,104,'日常织机',44,INK,650,extra='letter-spacing="-2"')
text(292,101,'把微小的坚持，与一闪而过的灵感，织在一起。',16,DIM)
mono(1418,49,'06 SEP 2026',11,INK,extra='text-anchor="end"')
mono(1418,80,'402 × 874 PT / NATIVE iOS',10,DIM,extra='text-anchor="end"')
line(84,123,1418,123,'#C8CCC1')

def start_phone(x,index,label):
    group(f'translate({x} 153)')
    rect(-1,-1,404,876,BG,'rx="44" stroke="#BCC1B8" stroke-width=".8" filter="url(#deviceShadow)"')
    e('<g clip-path="url(#phoneClip)">')
    rect(0,0,402,874,BG)
    text(31,33,'9:41',14,INK,650)
    rect(142,10,118,28,INK,'rx="14"')
    for n,h in enumerate([4,7,10,13]): rect(309+n*5,31-h,3,h,INK,'rx="1"')
    path('M337 23Q345 16 353 23M340 26Q345 21 350 26M344 29L346 29',INK,1.8,extra='stroke-linecap="round"')
    rect(361,20,23,12,'none','rx="3" stroke="#202A2B" stroke-width="1"')
    rect(363,22,18,8,INK,'rx="1.5"'); rect(385,24,2,4,INK,'rx="1"')
    mono(24,76,f'0{index}   /   {label}',10,INK,extra='letter-spacing="1.6"')
def nav(active):
    rect(0,776,402,98,BG)
    line(24,778,378,778,'#B8BEB2',.8)
    for i,label in enumerate(['今天','习惯','收集']):
        x=24+i*70
        text(x,821,label,15,INK if i==active else DIM,600 if i==active else 400)
        if i==active: line(x,834,x+30,834,INK,2)
    path('M258 813Q278 789 318 790Q353 790 378 813Q353 837 318 837Q281 837 258 813Z',INK,.6,INK)
    path('M279 807L279 819M273 813L285 813',BG,1.4,extra='stroke-linecap="round"')
    text(298,819,'拾起',14,BG,600)
    rect(133,857,136,5,INK,'rx="2.5"')
def finish_phone(x,index,label,caption):
    end();end()
    mono(x,1057,f'0{index}   {label}',10,INK,extra='letter-spacing="1.4"')
    text(x,1082,caption,12,DIM)

start_phone(84,1,'TODAY / ON THE LOOM')
text(20,159,'06',92,INK,500,extra='font-family="Helvetica Neue, Arial, sans-serif" letter-spacing="-7"')
text(153,125,'九月',18,INK,600)
text(153,150,'星期日',13,DIM)
line(218,105,218,157,LINE,.8)
text(245,126,'5',32,BLUE,650)
text(271,126,'/ 8',15,DIM,500)
mono(245,149,'THREADS WOVEN',8.5,DIM,extra='letter-spacing=".8"')
text(24,214,'今天，织一点。',34,INK,650,extra='letter-spacing="-1.4"')
text(25,242,'不必完美，每一根线都算数。',12,DIM)

# Warp/weft are sampled from a saddle-like surface. No bitmap hero is embedded.
group('translate(15 260)')
e('<ellipse cx="187" cy="269" rx="118" ry="15" fill="#202A2B" opacity=".15" filter="url(#fabricShadow)"/>')
def surface(u,v):
    return (31+251*u+33*sin(pi*v)+17*sin(pi*u)*sin(2*pi*v),
            38+209*v-43*u*cos(pi*v)+22*sin(2*pi*u+pi*v))
def curved(points):
    return 'M'+'L'.join(f'{x:.2f} {y:.2f}' for x,y in points)
bands=[BLUE,BLUE,RUST,LIME,BLUE,'#B6B9A9','#D8D9BE','#CED0BF']
# Translucent intersections retain a visible open weave at unfinished habit lanes.
for i in range(40):
    u=(i+.5)/40
    color=bands[min(7,int(u*8))]
    pts=[surface(i/40,0),surface((i+1)/40,0)]
    pts += [surface((i+1)/40,j/36) for j in range(1,37)]
    pts += [surface(i/40,j/36) for j in range(36,-1,-1)]
    path(curved(pts)+'Z','none',0,color,'opacity=".38"')
for i in range(101):
    u=i/100
    color=bands[min(7,int(u*8))]
    path(curved([surface(u,j/64) for j in range(65)]),color,.9 if i%3 else 1.6,extra='opacity=".88"')
for j in range(90):
    v=j/89
    color='#E5E4CF' if j%6<3 else '#202A2B'
    path(curved([surface(i/80,v) for i in range(81)]),color,.68,extra=f'opacity="{.54 if j%6<3 else .19}"')
# Satin-like catchlights and the exposed knotted lower edges.
for i in range(3,97,5):
    u=i/100; start=surface(u,1)
    path(f'M{start[0]:.2f} {start[1]:.2f}q-2 8 2 13',bands[min(7,int(u*8))],.7,extra='opacity=".72"')
for j in range(11,76,15):
    v=j/89
    path(curved([surface(i/80,v) for i in range(12,55)]),'#F6F3DA',.8,extra='opacity=".72"')
end()
# Small labels are visible, explicit controls anchored to the artwork.
path('M311 294L343 282L368 282',INK,.6)
text(317,272,'阅读',11,INK,550)
circle(306,296,3,BLUE)
path('M56 435L30 451L20 451',INK,.6)
text(23,471,'喝水',11,INK,550)
circle(61,432,3,BLUE)
path('M298 519L321 546L367 546',INK,.6)
text(323,564,'锻炼',11,INK,550)
circle(294,514,3,RUST)
mono(24,602,'JUST CAUGHT',9,DIM,extra='letter-spacing="1.5"')
text(24,628,'灵感，先留一线。',19,INK,600)
text(369,626,'↗',20,INK,400,extra='text-anchor="end"')
group('translate(23 648) rotate(-2 177 45)')
path('M0 0H354V86L344 81L334 86L324 81L314 86L304 81L294 86L284 81L274 86L264 81L254 86L244 81L234 86L224 81L214 86L204 81L194 86L184 81L174 86L164 81L154 86L144 81L134 86L124 81L114 86L104 81L94 86L84 81L74 86L64 81L54 86L44 81L34 86L24 81L14 86L0 82Z','none',0,LIME)
for i in range(11): circle(16+i*32,9,2,BG)
mono(17,30,'01 / NOTE',8.5,INK)
text(17,57,'把生活过成收集，而不是赶路。',15,INK,500)
mono(336,75,'09:18',8,INK,extra='text-anchor="end"')
end()
nav(0)
finish_phone(84,1,'TODAY','松弛的线，被今天的一次行动轻轻拉紧。')

start_phone(550,2,'HABITS / EVERY THREAD COUNTS')
text(22,126,'把日子，织起来。',33,INK,650,extra='letter-spacing="-1.5"')
text(24,155,'一根线，一个习惯。',12,DIM)
text(24,195,'08.31 — 09.06',21,INK,550,extra='font-family="Helvetica Neue, Arial, sans-serif"')
path('M315 180L308 187L315 194',INK,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
path('M351 180L358 187L351 194',DIM,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
line(24,215,378,215,LINE,.8)
mono(24,242,'THREAD',8.5,DIM,extra='letter-spacing=".8"')
text(24,272,'习惯',12,INK,550)
e('<g clip-path="url(#matrixClip)">')
rect(334,250,44,385,'#E5E8D0')
days=['一','二','三','四','五','六','日']; dates=['31','01','02','03','04','05','06']
for c in range(7):
    x=92+c*44
    mono(x,242,days[c],10,DIM,extra='text-anchor="middle"')
    if c==6:
        circle(x,266,17,INK)
        mono(x,270,dates[c],12,BG,extra='text-anchor="middle"')
    else: mono(x,270,dates[c],12,INK,extra='text-anchor="middle"')
    line(x,293,x,642,'#C8CCBA',.65)
rows=[('阅读','每天',BLUE,[1,1,0,1,1,0,1]),('喝水','每天',BLUE,[1,1,1,0,1,1,1]),('锻炼','周一 / 三 / 日',RUST,[1,None,1,None,None,None,1]),('早睡','每天',LIME,[1,1,1,1,0,0,0]),('冥想','每天',BLUE,[0,1,0,1,1,0,0])]
for r,(name,subtitle,color,states) in enumerate(rows):
    y=326+r*69
    for offset in [-2,0,2]: line(82,y+offset,400,y+offset,color,.65,extra='opacity=".25"')
    for c,state in enumerate(states):
        x=92+c*44
        if state is None:
            line(x-3,y,x+3,y,'#B9BEAE',1.2)
        elif state:
            dark='#8A9E22' if color==LIME else color
            path(f'M{x-6} {y-3}Q{x+1} {y-8} {x+6} {y+1}Q{x+1} {y+9} {x-6} {y+3}Z',dark,1.5,dark)
            path(f'M{x-6} {y+3}Q{x+3} {y-3} {x+6} {y-3}',BG,1.15,extra='opacity=".8"')
            path(f'M{x-2} {y+1}L{x} {y+3}L{x+4} {y-2}',BG,1.1,extra='stroke-linecap="round" stroke-linejoin="round"')
        else: circle(x,y,7,BG,extra='stroke="#A9B09B" stroke-width="1.1"')
end()
# Fixed labels overlay the horizontally scrolling 44pt day cells.
rect(24,292,95,352,BG)
for r,(name,subtitle,color,states) in enumerate(rows):
    y=326+r*69
    circle(28,y-7,2.5,'#8A9E22' if color==LIME else color)
    text(39,y-2,name,15,INK,600)
    text(25,y+17,subtitle,8.5,DIM)
    mono(103,y-4,'⋮',15,DIM)
rect(120,291,14,354,'url(#matrixFade)')
line(24,650,378,650,LINE,.7)
mono(24,677,'↔',15,INK)
text(48,675,'左右滑动时间 · 点线结打卡',10.5,DIM)
line(292,672,370,672,'#C3C8B5',2.5)
line(311,672,370,672,INK,2.5)
path('M33 706V720M26 713H40',INK,1.2)
text(51,718,'添加一根线',14,INK,550)
mono(24,752,'5 THREADS SHOWN / 8 IN TOTAL',8,DIM,extra='letter-spacing=".8"')
nav(1)
finish_phone(550,2,'HABITS','44 pt 可点击时间格，清楚记录每次完成。')

start_phone(1016,3,'COLLECTION / MATERIAL ARCHIVE')
text(23,126,'拾起，一闪而过。',32,INK,650,extra='letter-spacing="-1.5"')
text(24,155,'文字、声音、远处的一个链接。',12,DIM)
line(24,215,378,215,INK,.8)
circle(33,189,6,'none','stroke="#202A2B" stroke-width="1.2"')
line(37,194,42,199,INK,1.2)
text(54,194,'寻找一根线索',14,DIM)
for i,label in enumerate(['全部','文字','声音','链接']):
    x=24+i*64
    text(x,246,label,12,INK if i==0 else DIM,600 if i==0 else 400)
    if i==0: line(x,256,x+25,256,INK,1.6)
text(376,246,'标签 ⌄',11,DIM,extra='text-anchor="end"')
mono(24,292,'SEP 06 / SUNDAY',9,DIM,extra='letter-spacing="1.2"')
mono(378,292,'03 PIECES',9,DIM,extra='text-anchor="end"')

# Perforated note: ordinary corners, cut circular holes, horizontal readable copy.
group('translate(24 308)')
rect(0,0,354,163,'url(#paperShade)')
for y in range(14,160,23):
    circle(0,y,3,BG); circle(354,y,3,BG)
line(39,0,39,163,'#A7BE45',.7,extra='stroke-dasharray="2 3" opacity=".55"')
mono(14,25,'01',9,INK)
mono(54,25,'TEXT / 09:18',8.5,INK,extra='letter-spacing=".6"')
mono(337,25,'↗',15,INK,extra='text-anchor="end"')
text(53,68,'把生活过成收集，',19,INK,600)
text(53,96,'而不是赶路。',19,INK,600)
line(54,114,332,114,'#A5B450',.6,extra='opacity=".5"')
text(54,143,'# 日常切片',10,INK)
mono(332,143,'EDIT  ···',8.5,INK,extra='text-anchor="end"')
end()

# Abstract, equal-height etched texture; saved audio has no sampled waveform data.
group('translate(24 489)')
rect(0,0,354,132,'url(#tapeShade)')
for x in range(8,350,14):
    rect(x,0,6,4,BG); rect(x,128,6,4,BG)
mono(15,24,'02',9,'#E0E6FF')
mono(53,24,'VOICE / 08:42',8.5,'#E0E6FF',extra='letter-spacing=".6"')
text(53,50,'走路时想到的事',16,'#FFFFFF',550)
circle(32,85,17,'none','stroke="#FFFFFF" stroke-width=".8" opacity=".85"')
path('M28 77L39 85L28 93Z','none',0,'#F3F0E8')
for i in range(61):
    x=62+i*4
    height=22
    line(x,86-height/2,x,86+height/2,'#E0E6FF',.65,extra='opacity=".72"')
for y in [78,82,86,90,94]:
    line(62,y,302,y,'#E0E6FF',.45,extra='opacity=".45"')
mono(334,116,'00:42',9,'#E0E6FF',extra='text-anchor="end"')
text(53,116,'# 在路上',9,'#E0E6FF')
end()

# Folded linked paper: front faces are flat so title and source stay legible.
group('translate(24 640)')
path('M0 0H328L354 26V112H0Z','#D6D8CA',.7,'#FBFBF2')
path('M328 0V26H354','none',0,'#DDDCCF')
line(328,26,354,26,'#BEC2B4',.7)
mono(15,25,'03',9,DIM)
mono(53,25,'LINK / 08:26',8.5,DIM,extra='letter-spacing=".6"')
text(53,56,'给生活留一点无用之美',16,INK,600)
text(53,82,'设计笔记 · are.na',10,DIM)
text(332,89,'↗',18,INK,400,extra='text-anchor="end"')
end()
nav(2)
finish_phone(1016,3,'COLLECTION','纸、磁带、薄片；内容本身成为界面。')

line(84,1112,1418,1112,'#C8CCC1',.7)
mono(84,1135,'WARM PAPER / TENSION / TRUE DATA / QUIET MOTION',8.5,INK,extra='letter-spacing="1.2"')
for i,(color,label) in enumerate([(BG,'PAPER'),(INK,'INK'),(BLUE,'COBALT'),(LIME,'ACID'),(RUST,'CLAY')]):
    x=1036+i*77
    rect(x,1126,11,11,color,'stroke="#B4B9AB" stroke-width=".4"')
    mono(x+16,1135,label,7,DIM)
end(); e('</svg>')
(ROOT/'blueprint.svg').write_text('\n'.join(out),encoding='utf-8')
print(ROOT/'blueprint.svg')
